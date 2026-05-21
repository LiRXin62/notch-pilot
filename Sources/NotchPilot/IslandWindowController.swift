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
    private let onShowSettings: () -> Void
    private let window: NSPanel
    private let runtimeState = IslandRuntimeState()
    private var cancellables = Set<AnyCancellable>()
    private var state: IslandPresentationState = .compact
    private var collapseTask: DispatchWorkItem?

    init(
        store: AppStore,
        notificationService: NotificationService,
        onShowSettings: @escaping () -> Void
    ) {
        self.store = store
        self.notificationService = notificationService
        self.onShowSettings = onShowSettings
        window = IslandPanel(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init()
        configureWindow()
        configureContent()
        observeSettings()
        observeScreenChanges()
    }

    func showCompact() {
        state = .compact
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            runtimeState.isExpanded = false
        }
        resizeForCurrentState(animated: false)
        window.orderFrontRegardless()
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
        resizeForCurrentState(animated: true)
        window.orderFrontRegardless()
    }

    func collapse() {
        collapseTask?.cancel()
        state = .compact
        withAnimation(.spring(response: 0.24, dampingFraction: 0.96)) {
            runtimeState.isExpanded = false
        }
        resizeForCurrentState(animated: true)
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

    private func configureWindow() {
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

    private func configureContent() {
        let rootView = IslandRootView(
            store: store,
            runtimeState: runtimeState,
            notificationService: notificationService,
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
                    self?.resizeForCurrentState(animated: false)
                }
            }
            .store(in: &cancellables)
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
        resizeForCurrentState(animated: false)
    }

    private func resizeForCurrentState(animated: Bool) {
        let frame = IslandPositioner.frame(for: state, settings: store.settings)
        guard animated else {
            window.setFrame(frame, display: true)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = state == .expanded ? 0.30 : 0.22
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.18, 0.82, 0.18, 1.0)
            window.animator().setFrame(frame, display: true)
        }
    }
}

@MainActor
enum IslandPositioner {
    static func frame(for state: IslandPresentationState, settings: AppSettings) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let safeInsets = screen?.safeAreaInsets ?? NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

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
