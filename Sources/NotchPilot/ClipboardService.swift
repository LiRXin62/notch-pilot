import AppKit
import Combine

struct ClipboardEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var content: String
    var isPinned: Bool = false
    var isSensitive: Bool = false
    var timestamp: Date = Date()
}

@MainActor
final class ClipboardService: ObservableObject {
    @Published var entries: [ClipboardEntry] = []
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let storageURL: URL

    init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("NotchPilot", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        storageURL = dir.appendingPathComponent("clipboard.json")

        lastChangeCount = NSPasteboard.general.changeCount
        load()

        $entries
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func copyToPasteboard(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }

    func togglePin(_ entry: ClipboardEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].isPinned.toggle()
        }
    }

    func delete(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func clearUnpinned() {
        entries.removeAll { !$0.isPinned }
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Deduplicate - move to top if already exists
        if let existingIndex = entries.firstIndex(where: { $0.content == text }) {
            var existing = entries.remove(at: existingIndex)
            existing.timestamp = Date()
            entries.insert(existing, at: 0)
            return
        }

        let isSensitive = Self.detectSensitiveContent(text)
        let entry = ClipboardEntry(content: text, isSensitive: isSensitive)
        entries.insert(entry, at: 0)

        // Keep max 100 entries (excluding pinned)
        let unpinned = entries.filter { !$0.isPinned }
        if unpinned.count > 100 {
            let toRemove = unpinned.suffix(unpinned.count - 100)
            for item in toRemove {
                entries.removeAll { $0.id == item.id }
            }
        }
    }

    private static func detectSensitiveContent(_ text: String) -> Bool {
        let patterns = [
            "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b", // Credit card
            "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b", // Email
            "\\b\\d{18}\\b", // Chinese ID
        ]
        for pattern in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? decoder.decode([ClipboardEntry].self, from: data) else { return }
        entries = loaded
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: storageURL, options: [.atomic])
    }
}
