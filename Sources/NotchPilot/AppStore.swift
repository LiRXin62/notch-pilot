import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var settings: AppSettings
    @Published var todos: [TodoItem]
    @Published var launchItems: [LaunchItem]
    @Published var shelfItems: [ShelfItem]
    @Published var notes: [QuickNote]

    private let storageURL: URL

    init(snapshot: AppSnapshot, storageURL: URL) {
        self.settings = snapshot.settings
        self.todos = snapshot.todos
        self.launchItems = snapshot.launchItems
        self.shelfItems = snapshot.shelfItems
        self.notes = snapshot.notes
        self.storageURL = storageURL
        normalizeSettings()
    }

    static func load() -> AppStore {
        let url = Self.storageURL()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: url),
           let snapshot = try? decoder.decode(AppSnapshot.self, from: data) {
            return AppStore(snapshot: snapshot, storageURL: url)
        }
        return AppStore(snapshot: AppSnapshot(), storageURL: url)
    }

    func snapshot() -> AppSnapshot {
        AppSnapshot(
            settings: settings,
            todos: todos,
            launchItems: launchItems,
            shelfItems: shelfItems,
            notes: notes
        )
    }

    func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(snapshot())
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("NotchPilot save failed: \(error)")
        }
    }

    func replace(with snapshot: AppSnapshot) {
        settings = snapshot.settings
        todos = snapshot.todos
        launchItems = snapshot.launchItems
        shelfItems = snapshot.shelfItems
        notes = snapshot.notes
        persist()
    }

    func reset() {
        replace(with: AppSnapshot())
    }

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        var next = settings
        mutate(&next)
        settings = next
        normalizeSettings()
        persist()
    }

    func activeModule() -> IslandModuleKind {
        if let active = IslandModuleKind(rawValue: settings.activeModuleRawValue),
           isModuleEnabled(active) {
            return active
        }
        return visibleModules().first ?? .dashboard
    }

    func visibleModules() -> [IslandModuleKind] {
        settings.moduleOrderIDs.compactMap { IslandModuleKind(rawValue: $0) }.filter { isModuleEnabled($0) }
    }

    func isModuleEnabled(_ module: IslandModuleKind) -> Bool {
        settings.enabledModuleIDs.contains(module.rawValue)
    }

    func setActiveModule(_ module: IslandModuleKind) {
        updateSettings { $0.activeModuleRawValue = module.rawValue }
    }

    func toggleModuleEnabled(_ module: IslandModuleKind) {
        updateSettings { settings in
            if let index = settings.enabledModuleIDs.firstIndex(of: module.rawValue) {
                settings.enabledModuleIDs.remove(at: index)
            } else {
                settings.enabledModuleIDs.append(module.rawValue)
            }
        }
        if !isModuleEnabled(activeModule()) {
            let fallback = visibleModules().first ?? .dashboard
            updateSettings { $0.activeModuleRawValue = fallback.rawValue }
        }
    }

    func moveModule(_ module: IslandModuleKind, offset: Int) {
        updateSettings { settings in
            guard let index = settings.moduleOrderIDs.firstIndex(of: module.rawValue) else { return }
            let nextIndex = min(max(index + offset, 0), settings.moduleOrderIDs.count - 1)
            guard nextIndex != index else { return }
            settings.moduleOrderIDs.remove(at: index)
            settings.moduleOrderIDs.insert(module.rawValue, at: nextIndex)
        }
    }

    func addTodo(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todos.insert(TodoItem(title: trimmed), at: 0)
        persist()
    }

    func toggleTodo(_ id: TodoItem.ID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isCompleted.toggle()
        todos[index].updatedAt = Date()
        persist()
    }

    func deleteTodo(_ id: TodoItem.ID) {
        todos.removeAll { $0.id == id }
        persist()
    }

    func addLaunchApp(url: URL) {
        let title = url.deletingPathExtension().lastPathComponent
        let bundleIdentifier = Bundle(url: url)?.bundleIdentifier ?? ""
        let item = LaunchItem(title: title, path: url.path, bundleIdentifier: bundleIdentifier)
        launchItems.removeAll { $0.path == item.path }
        launchItems.insert(item, at: 0)
        persist()
    }

    func launchApp(_ item: LaunchItem) {
        NSWorkspace.shared.open(URL(fileURLWithPath: item.path))
    }

    func deleteLaunchItem(_ id: LaunchItem.ID) {
        launchItems.removeAll { $0.id == id }
        persist()
    }

    func addShelfItems(urls: [URL]) {
        let newItems = urls.map { url in
            ShelfItem(fileName: url.lastPathComponent, path: url.path)
        }
        for item in newItems.reversed() {
            shelfItems.removeAll { $0.path == item.path }
            shelfItems.insert(item, at: 0)
        }
        persist()
    }

    func deleteShelfItem(_ id: ShelfItem.ID) {
        shelfItems.removeAll { $0.id == id }
        persist()
    }

    func clearShelf() {
        shelfItems.removeAll()
        persist()
    }

    func revealInFinder(_ item: ShelfItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }

    func addNote(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        notes.insert(QuickNote(content: trimmed), at: 0)
        persist()
    }

    func deleteNote(_ id: QuickNote.ID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    func convertNoteToTodo(_ note: QuickNote) {
        addTodo(title: note.content)
        deleteNote(note.id)
    }

    func snapshotData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot())
    }

    func importSnapshot(from url: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: url)
        let snapshot = try decoder.decode(AppSnapshot.self, from: data)
        replace(with: snapshot)
    }

    func exportSnapshot(to url: URL) throws {
        let data = try snapshotData()
        try data.write(to: url, options: [.atomic])
    }

    private func normalizeSettings() {
        let available = Set(IslandModuleKind.allCases.map(\.rawValue))
        let allIDs = IslandModuleKind.allCases.map(\.rawValue)
        if settings.enabledModuleIDs == allIDs {
            settings.enabledModuleIDs = IslandModuleKind.defaultEnabledIDs
        }
        settings.compactHeight = min(max(settings.compactHeight, 32), 40)
        settings.hoverDelay = min(max(settings.hoverDelay, 0.04), 0.35)
        settings.enabledModuleIDs = settings.enabledModuleIDs.filter(available.contains)
        settings.moduleOrderIDs = settings.moduleOrderIDs.filter(available.contains)
        if settings.moduleOrderIDs.isEmpty {
            settings.moduleOrderIDs = IslandModuleKind.allCases.map(\.rawValue)
        }
        if settings.enabledModuleIDs.isEmpty {
            settings.enabledModuleIDs = IslandModuleKind.allCases.map(\.rawValue)
        }
    }

    private static func storageURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = base.appendingPathComponent("NotchPilot", isDirectory: true)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("state.json")
    }
}

extension AppStore {
    func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { [weak self] newValue in
                self?.updateSettings { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    func moduleEnabledBinding(_ module: IslandModuleKind) -> Binding<Bool> {
        Binding(
            get: { self.isModuleEnabled(module) },
            set: { [weak self] isOn in
                guard let self else { return }
                if isOn != self.isModuleEnabled(module) {
                    self.toggleModuleEnabled(module)
                }
            }
        )
    }
}
