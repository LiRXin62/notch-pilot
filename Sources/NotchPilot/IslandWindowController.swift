import AppKit
import Combine
import QuartzCore
import SwiftUI

enum IslandPresentationState {
    case compact
    case expanded
}

@MainActor
final class IslandRuntimeState: ObservableObject {
    @Published var isExpanded = false
}

final class IslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class IslandWindowController: NSObject {
    private let store: AppStore
    private let notificationService: NotificationService
    private let localizer: Localizer
    private let onShowSettings: () -> Void
    private var windows: [NSPanel] = []
    private let runtimeState = IslandRuntimeState()
    private var cancellables = Set<AnyCancellable>()
    private var state: IslandPresentationState = .compact
    private var collapseTask: DispatchWorkItem?
    private var isHiddenByFullscreen = false

    init(
        store: AppStore,
        notificationService: NotificationService,
        localizer: Localizer,
        onShowSettings: @escaping () -> Void
    ) {
        self.store = store
        self.notificationService = notificationService
        self.localizer = localizer
        self.onShowSettings = onShowSettings
        super.init()
        createWindows()
        observeSettings()
        observeScreenChanges()
        observeFullscreenChanges()
    }

    func showCompact() {
        state = .compact
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            runtimeState.isExpanded = false
        }
        resizeAllWindows(animated: false)
        for window in windows {
            window.orderFrontRegardless()
        }
    }

    func toggleExpanded() {
        switch state {
        case .compact:
            expand()
        case .expanded:
            collapse()
        }
    }

    func expand() {
        collapseTask?.cancel()
        state = .expanded
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            runtimeState.isExpanded = true
        }
        resizeAllWindows(animated: true)
        for window in windows {
            window.orderFrontRegardless()
        }
    }

    func collapse() {
        collapseTask?.cancel()
        state = .compact
        withAnimation(.spring(response: 0.24, dampingFraction: 0.96)) {
            runtimeState.isExpanded = false
        }
        resizeAllWindows(animated: true)
    }

    func scheduleCollapse() {
        guard state == .expanded else { return }
        collapseTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.collapse()
        }
        collapseTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: task)
    }

    private func createWindows() {
        let screens = store.settings.showOnAllDisplays ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        windows.removeAll()

        for screen in screens {
            let window = IslandPanel(
                contentRect: .zero,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            configureWindow(window, for: screen)
            configureContent(window)
            windows.append(window)
        }
    }

    private func configureWindow(_ window: NSPanel, for screen: NSScreen) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }

    private func configureContent(_ window: NSPanel) {
        let rootView = IslandRootView(
            store: store,
            runtimeState: runtimeState,
            notificationService: notificationService,
            localizer: localizer,
            onExpand: { [weak self] in self?.expand() },
            onCollapse: { [weak self] in self?.collapse() },
            onScheduleCollapse: { [weak self] in self?.scheduleCollapse() },
            onShowSettings: onShowSettings
        )
        window.contentView = NSHostingView(rootView: rootView)
    }

    private func observeSettings() {
        store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleSettingsChange()
                }
            }
            .store(in: &cancellables)
    }

    private func handleSettingsChange() {
        let shouldShowOnAll = store.settings.showOnAllDisplays
        let currentCount = windows.count
        let expectedCount = shouldShowOnAll ? NSScreen.screens.count : 1

        if currentCount != expectedCount {
            for window in windows {
                window.close()
            }
            createWindows()
            showCompact()
        } else {
            resizeAllWindows(animated: false)
        }

        DispatchQueue.main.async { [weak self] in
            self?.checkFullscreenState()
        }
    }

    private func observeScreenChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        let screens = store.settings.showOnAllDisplays ? NSScreen.screens : [NSScreen.main].compactMap { $0 }

        if windows.count != screens.count {
            for window in windows {
                window.close()
            }
            createWindows()
            showCompact()
        } else {
            resizeAllWindows(animated: false)
        }
    }

    private func observeFullscreenChanges() {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.checkFullscreenState()
            }
        }
        checkFullscreenState()
    }

    private func checkFullscreenState() {
        guard store.settings.hideInFullscreen else {
            if isHiddenByFullscreen {
                isHiddenByFullscreen = false
                for window in windows { window.orderFrontRegardless() }
            }
            return
        }

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let ownPID = NSRunningApplication.current.processIdentifier

        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        let hasFullscreen = windowList.contains { info in
            guard
                let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid != ownPID,
                let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                let x = bounds["X"], let y = bounds["Y"],
                let w = bounds["Width"], let h = bounds["Height"]
            else { return false }

            return abs(x - screenFrame.origin.x) < 2
                && abs(y - screenFrame.origin.y) < 2
                && abs(w - screenFrame.width) < 2
                && abs(h - screenFrame.height) < 2
        }

        if hasFullscreen && !isHiddenByFullscreen {
            isHiddenByFullscreen = true
            for window in windows { window.orderOut(nil) }
        } else if !hasFullscreen && isHiddenByFullscreen {
            isHiddenByFullscreen = false
            for window in windows { window.orderFrontRegardless() }
        }
    }

    private func resizeAllWindows(animated: Bool) {
        let screens = store.settings.showOnAllDisplays ? NSScreen.screens : [NSScreen.main].compactMap { $0 }

        for (index, screen) in screens.enumerated() {
            guard index < windows.count else { break }
            let frame = IslandPositioner.frame(for: state, settings: store.settings, screen: screen)
            let window = windows[index]

            guard animated else {
                window.setFrame(frame, display: true)
                continue
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = state == .expanded ? 0.30 : 0.22
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.18, 0.82, 0.18, 1.0)
                window.animator().setFrame(frame, display: true)
            }
        }
    }
}

@MainActor
enum IslandPositioner {
    static func frame(for state: IslandPresentationState, settings: AppSettings, screen: NSScreen? = nil) -> NSRect {
        let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = targetScreen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let safeInsets = targetScreen?.safeAreaInsets ?? NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let width: CGFloat
        let height: CGFloat
        switch state {
        case .compact:
            width = min(CGFloat(settings.compactWidth), screenFrame.width * 0.46)
            height = min(CGFloat(settings.compactHeight), 40)
        case .expanded:
            width = min(CGFloat(settings.expandedWidth), screenFrame.width * 0.82)
            height = min(CGFloat(settings.expandedHeight), screenFrame.height * 0.68)
        }

        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - height - (safeInsets.top > 0 ? 0 : 1)
        return NSRect(x: x.rounded(), y: y.rounded(), width: width.rounded(), height: height.rounded())
    }
}
