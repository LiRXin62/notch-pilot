import AppKit
import Foundation

struct ShortcutItem: Identifiable, Equatable {
    let id: String
    let name: String
    var isRunning: Bool = false
}

@MainActor
final class ShortcutsService: ObservableObject {
    @Published var shortcuts: [ShortcutItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchShortcuts() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
                process.arguments = ["list"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                await MainActor.run {
                    self.shortcuts = output
                        .components(separatedBy: .newlines)
                        .filter { !$0.isEmpty }
                        .map { ShortcutItem(id: $0, name: $0) }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "获取快捷指令失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func runShortcut(_ shortcut: ShortcutItem) {
        guard let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }
        shortcuts[index].isRunning = true

        Task {
            do {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
                process.arguments = ["run", shortcut.name]

                try process.run()
                process.waitUntilExit()

                await MainActor.run {
                    self.shortcuts[index].isRunning = false
                    if process.terminationStatus != 0 {
                        self.errorMessage = "执行 \(shortcut.name) 失败"
                    }
                }
            } catch {
                await MainActor.run {
                    self.shortcuts[index].isRunning = false
                    self.errorMessage = "执行失败: \(error.localizedDescription)"
                }
            }
        }
    }
}
