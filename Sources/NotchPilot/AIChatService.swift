import Foundation

struct AIChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: String // "user", "assistant", "system"
    var content: String
    var timestamp: Date = Date()
}

@MainActor
final class AIChatService: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tokenUsage: Int = 0

    private var streamTask: Task<Void, Never>?

    func send(_ text: String, settings: AppSettings) {
        let apiKey = KeychainHelper.load(key: "aiAPIKey") ?? settings.aiAPIKey
        guard !apiKey.isEmpty else {
            errorMessage = Localizer.shared.t("请先在设置中配置 API Key")
            return
        }

        let userMessage = AIChatMessage(role: "user", content: text)
        messages.append(userMessage)
        errorMessage = nil

        streamTask?.cancel()
        streamTask = Task { [weak self] in
            await self?.performRequest(apiKey: apiKey, settings: settings)
        }
    }

    func clearHistory() {
        messages.removeAll()
        tokenUsage = 0
        errorMessage = nil
    }

    func stopGeneration() {
        streamTask?.cancel()
        isLoading = false
    }

    private func performRequest(apiKey: String, settings: AppSettings) async {
        isLoading = true

        let baseURL = settings.aiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = Localizer.shared.t("URL 无效")
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": settings.aiModelName,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = Localizer.shared.t("请求构造失败")
            }
            return
        }

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard !Task.isCancelled else { return }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200 else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = statusCode == 401 ? Localizer.shared.t("API Key 无效") : Localizer.shared.t("请求失败") + " (\(statusCode))"
                }
                return
            }

            var assistantMessage = AIChatMessage(role: "assistant", content: "")
            await MainActor.run {
                self.messages.append(assistantMessage)
            }

            for try await line in bytes.lines {
                guard !Task.isCancelled else { return }
                guard line.hasPrefix("data: ") else { continue }
                let data = line.dropFirst(6)
                guard data != "[DONE]" else { continue }

                guard let jsonData = data.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any],
                      let content = delta["content"] as? String else { continue }

                assistantMessage.content += content
                await MainActor.run {
                    if let lastIndex = self.messages.indices.last {
                        self.messages[lastIndex].content = assistantMessage.content
                    }
                }

                if let usage = json["usage"] as? [String: Any],
                   let total = usage["total_tokens"] as? Int {
                    await MainActor.run {
                        self.tokenUsage = total
                    }
                }
            }

            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
