import AppKit

@MainActor
final class HotkeyMonitor {
    var onToggleIsland: (() -> Void)?
    var onShowSettings: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        stop()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains([.command, .option]) else { return }
        guard let characters = event.charactersIgnoringModifiers?.lowercased() else { return }
        switch characters {
        case "i":
            DispatchQueue.main.async { [weak self] in self?.onToggleIsland?() }
        case ",":
            DispatchQueue.main.async { [weak self] in self?.onShowSettings?() }
        default:
            break
        }
    }
}
