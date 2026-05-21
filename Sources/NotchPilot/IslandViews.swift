import AppKit
import SwiftUI

struct IslandRootView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var runtimeState: IslandRuntimeState
    let notificationService: NotificationService
    let onExpand: () -> Void
    let onCollapse: () -> Void
    let onScheduleCollapse: () -> Void
    let onShowSettings: () -> Void

    @StateObject private var timerModel: PomodoroModel
    @State private var now = Date()
    @State private var isHovering = false

    init(
        store: AppStore,
        runtimeState: IslandRuntimeState,
        notificationService: NotificationService,
        onExpand: @escaping () -> Void,
        onCollapse: @escaping () -> Void,
        onScheduleCollapse: @escaping () -> Void,
        onShowSettings: @escaping () -> Void
    ) {
        self.store = store
        self.runtimeState = runtimeState
        self.notificationService = notificationService
        self.onExpand = onExpand
        self.onCollapse = onCollapse
        self.onScheduleCollapse = onScheduleCollapse
        self.onShowSettings = onShowSettings
        _timerModel = StateObject(wrappedValue: PomodoroModel(store: store, notificationService: notificationService))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            IslandBackground(isExpanded: runtimeState.isExpanded)
            if runtimeState.isExpanded {
                ExpandedIslandView(
                    store: store,
                    timerModel: timerModel,
                    now: now,
                    onCollapse: onCollapse,
                    onShowSettings: onShowSettings
                )
            } else {
                CompactIslandView(store: store, timerModel: timerModel, now: now)
            }
        }
        .contentTransition(.opacity)
        .animation(.spring(response: 0.28, dampingFraction: 0.92), value: runtimeState.isExpanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onHover { hovering in
            isHovering = hovering
            if hovering, store.settings.expandOnHover {
                DispatchQueue.main.asyncAfter(deadline: .now() + store.settings.hoverDelay) {
                    if isHovering {
                        onExpand()
                    }
                }
            } else if !hovering {
                onScheduleCollapse()
            }
        }
        .onTapGesture {
            if !runtimeState.isExpanded {
                onExpand()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
            timerModel.tick()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    let data = item as? Data
                    let url = data.flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                    DispatchQueue.main.async {
                        if let url {
                            if url.pathExtension.lowercased() == "app" {
                                store.addLaunchApp(url: url)
                                store.setActiveModule(.launchers)
                            } else {
                                store.addShelfItems(urls: [url])
                                store.setActiveModule(.files)
                            }
                            onExpand()
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
}

struct IslandBackground: View {
    var isExpanded = false

    var body: some View {
        backgroundShape
            .fill(NPTheme.islandFill(isExpanded: isExpanded))
            .overlay(alignment: .top) {
                backgroundShape
                    .stroke(.white.opacity(isExpanded ? 0.13 : 0.18), lineWidth: 1)
                    .blendMode(.plusLighter)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.white.opacity(isExpanded ? 0.13 : 0.17), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: isExpanded ? 80 : 18)
                .clipShape(backgroundShape)
            }
            .overlay(alignment: .bottom) {
                backgroundShape
                    .stroke(.black.opacity(0.58), lineWidth: 0.8)
                    .blur(radius: 0.5)
                    .offset(y: 1)
                    .mask(
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    )
            }
            .shadow(color: .black.opacity(isExpanded ? 0.34 : 0.28), radius: isExpanded ? 34 : 18, x: 0, y: isExpanded ? 18 : 8)
            .shadow(color: .black.opacity(isExpanded ? 0.18 : 0.16), radius: isExpanded ? 8 : 5, x: 0, y: 2)
            .animation(.spring(response: 0.28, dampingFraction: 0.92), value: isExpanded)
    }

    private var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: isExpanded ? 30 : 19, style: .continuous)
    }
}

struct CompactIslandView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var timerModel: PomodoroModel
    let now: Date

    var body: some View {
        HStack(spacing: 8) {
            StatusChip(symbolName: "timer", text: timerModel.compactLabel, tint: NPTheme.amber)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(DateFormatters.time.string(from: now))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 58)

            StatusChip(symbolName: "checklist", text: "\(store.todos.filter { !$0.isCompleted }.count)", tint: NPTheme.green)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.98)),
            removal: .opacity.combined(with: .scale(scale: 0.985))
        ))
    }
}

struct ExpandedIslandView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var timerModel: PomodoroModel
    let now: Date
    let onCollapse: () -> Void
    let onShowSettings: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            header
            moduleStrip
            moduleContent
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
            removal: .opacity.combined(with: .scale(scale: 0.992, anchor: .top))
        ))
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatters.time.string(from: now))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(DateFormatters.date.string(from: now).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(NPTheme.secondaryText)
            }

            StatusChipButton(
                symbolName: "timer",
                text: timerModel.compactLabel,
                tint: NPTheme.amber,
                help: "打开专注计时"
            ) {
                store.setActiveModule(.timer)
            }
            StatusChipButton(
                symbolName: "checklist",
                text: "\(store.todos.filter { !$0.isCompleted }.count) 待办",
                tint: NPTheme.green,
                help: "打开待办"
            ) {
                store.setActiveModule(.todos)
            }
            StatusChipButton(
                symbolName: "folder",
                text: "\(store.shelfItems.count) 文件",
                tint: NPTheme.cyan,
                help: "打开文件暂存"
            ) {
                store.setActiveModule(.files)
            }

            Spacer()

            GhostIconButton(symbolName: "gearshape", help: "设置", action: onShowSettings)
            GhostIconButton(symbolName: "chevron.up", help: "收起", action: onCollapse)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .panelRow()
    }

    private var moduleStrip: some View {
        HStack(spacing: 8) {
            ForEach(store.visibleModules()) { module in
                IconToolButton(
                    symbolName: module.symbolName,
                    isActive: activeModule == module,
                    accent: accent(for: module),
                    help: module.title
                ) {
                    store.setActiveModule(module)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(height: 42)
        .panelRow()
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch activeModule {
        case .dashboard:
            DashboardModuleView(store: store, timerModel: timerModel, now: now)
        case .todos:
            TodoModuleView(store: store)
        case .timer:
            TimerModuleView(store: store, timerModel: timerModel)
        case .launchers:
            LauncherModuleView(store: store)
        case .files:
            FileShelfModuleView(store: store)
        case .notes:
            NotesModuleView(store: store)
        case .system:
            SystemModuleView()
        case .calendar:
            PlaceholderModuleView(
                title: "日程",
                symbolName: "calendar",
                message: "下一步接 EventKit，把今天的日历事件和提醒事项放进这里。"
            )
        case .clipboard:
            ClipboardModuleView()
        case .weather:
            PlaceholderModuleView(
                title: "天气",
                symbolName: "cloud.sun",
                message: "下一步配置天气 Provider，展示当前温度、天气和缓存结果。"
            )
        case .ai:
            PlaceholderModuleView(
                title: "AI",
                symbolName: "sparkles",
                message: "下一步接 OpenAI-compatible 接口，API Key 存入 Keychain。"
            )
        case .settings:
            InlineSettingsModuleView(store: store)
        }
    }

    private var activeModule: IslandModuleKind {
        store.activeModule()
    }

    private func accent(for module: IslandModuleKind) -> Color {
        switch module {
        case .dashboard, .files, .weather: return NPTheme.cyan
        case .todos, .system, .calendar: return NPTheme.green
        case .timer, .launchers, .clipboard: return NPTheme.amber
        case .notes, .ai, .settings: return NPTheme.rose
        }
    }
}
