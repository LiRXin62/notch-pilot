import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AppStore.load()
    private let notificationService = NotificationService()
    private let hotkeyMonitor = HotkeyMonitor()
    private var statusItem: NSStatusItem?
    private var islandController: IslandWindowController?
    private var settingsController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let islandController = IslandWindowController(
            store: store,
            notificationService: notificationService,
            onShowSettings: { [weak self] in self?.showSettings() }
        )
        self.islandController = islandController
        islandController.showCompact()

        configureStatusItem()
        configureHotkeys()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.persist()
        hotkeyMonitor.stop()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "capsule.tophalf.filled", accessibilityDescription: "Notch Pilot")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Island", action: #selector(showIsland), keyEquivalent: "i"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettingsAction), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Export Data...", action: #selector(exportData), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Import Data...", action: #selector(importData), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Notch Pilot", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func configureHotkeys() {
        hotkeyMonitor.onToggleIsland = { [weak self] in
            self?.islandController?.toggleExpanded()
        }
        hotkeyMonitor.onShowSettings = { [weak self] in
            self?.showSettings()
        }
        hotkeyMonitor.start()
    }

    @objc private func showIsland() {
        islandController?.showCompact()
    }

    @objc private func showSettingsAction() {
        showSettings()
    }

    private func showSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(store: store)
        }
        settingsController?.show()
    }

    @objc private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "notch-pilot-export.json"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                try self.store.exportSnapshot(to: url)
            } catch {
                presentError(error)
            }
        }
    }

    @objc private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                try self.store.importSnapshot(from: url)
            } catch {
                presentError(error)
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(store: AppStore) {
        let root = SettingsView(store: store)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notch Pilot Settings"
        window.center()
        window.contentView = NSHostingView(rootView: root)
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
