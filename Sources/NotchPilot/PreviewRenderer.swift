import AppKit
import SwiftUI

@MainActor
enum PreviewRenderer {
    static func run() {
        let compactURL = URL(fileURLWithPath: "/private/tmp/notchpilot-compact.png")
        let expandedURL = URL(fileURLWithPath: "/private/tmp/notchpilot-expanded.png")

        let store = sampleStore()
        let notificationService = NotificationService()
        let runtimeState = IslandRuntimeState()
        runtimeState.isExpanded = true

        let timerModel = PomodoroModel(store: store, notificationService: notificationService)

        let compactView = ZStack(alignment: .topLeading) {
            IslandBackground(isExpanded: false)
            CompactIslandView(store: store, timerModel: timerModel, now: Date())
        }
        .frame(width: 288, height: 36)
        .padding(4)

        let expandedView = ZStack(alignment: .topLeading) {
            IslandBackground(isExpanded: true)
            ExpandedIslandView(
                store: store,
                timerModel: timerModel,
                now: Date(),
                onCollapse: {},
                onShowSettings: {}
            )
        }
        .frame(width: 720, height: 430, alignment: .top)
        .padding(4)

        render(view: compactView, to: compactURL, size: CGSize(width: 296, height: 50))
        render(view: expandedView, to: expandedURL, size: CGSize(width: 728, height: 438))

        print("Rendered previews:")
        print(compactURL.path)
        print(expandedURL.path)
    }

    private static func sampleStore() -> AppStore {
        let snapshot = AppSnapshot(
            settings: AppSettings(
                compactWidth: 288,
                compactHeight: 36,
                expandedWidth: 720,
                expandedHeight: 430,
                expandOnHover: true,
                showOnAllDisplays: false,
                hideInFullscreen: false,
                showModuleIcons: true,
                hoverDelay: 0.08,
                activeModuleRawValue: IslandModuleKind.dashboard.rawValue,
                enabledModuleIDs: IslandModuleKind.allCases.map(\.rawValue),
                moduleOrderIDs: IslandModuleKind.allCases.map(\.rawValue),
                pomodoroFocusMinutes: 25,
                pomodoroBreakMinutes: 5
            ),
            todos: [
                TodoItem(title: "整理本周交付"),
                TodoItem(title: "回复客户消息", isCompleted: true),
                TodoItem(title: "写一版更干净的首页")
            ],
            launchItems: [
                LaunchItem(title: "Safari", path: "/Applications/Safari.app"),
                LaunchItem(title: "Notes", path: "/System/Applications/Notes.app"),
                LaunchItem(title: "Terminal", path: "/System/Applications/Utilities/Terminal.app")
            ],
            shelfItems: [
                ShelfItem(fileName: "brief.pdf", path: "/Users/example/Documents/brief.pdf"),
                ShelfItem(fileName: "screenshot.png", path: "/Users/example/Desktop/screenshot.png")
            ],
            notes: [
                QuickNote(content: "把顶部岛做成真正愿意常驻的工具，而不是 demo。"),
                QuickNote(content: "先把手感做好，再继续加模块。")
            ]
        )
        let store = AppStore(snapshot: snapshot, storageURL: URL(fileURLWithPath: "/private/tmp/notch-pilot-preview-state.json"))
        store.setActiveModule(.dashboard)
        return store
    }

    private static func render<V: View>(view: V, to url: URL, size: CGSize) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(size)
        renderer.isOpaque = false

        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            print("Failed to render preview at \(url.path)")
            return
        }

        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: [.atomic])
    }
}
