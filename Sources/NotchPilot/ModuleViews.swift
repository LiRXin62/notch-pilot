import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DashboardModuleView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var timerModel: PomodoroModel
    let now: Date

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 16) {
                ModuleHeader(
                    title: "今日总览",
                    subtitle: "把正在发生的事收进顶部",
                    symbolName: "rectangle.3.group",
                    tint: NPTheme.cyan
                )

                HStack(spacing: 10) {
                    SummaryTile(title: "待办", value: "\(store.todos.filter { !$0.isCompleted }.count)", symbolName: "checklist", tint: NPTheme.green)
                    SummaryTile(title: "专注", value: timerModel.remainingText, symbolName: "timer", tint: NPTheme.amber)
                    SummaryTile(title: "启动", value: "\(store.launchItems.count)", symbolName: "app", tint: NPTheme.rose)
                    SummaryTile(title: "文件", value: "\(store.shelfItems.count)", symbolName: "folder", tint: NPTheme.cyan)
                }

                HStack(alignment: .top, spacing: 10) {
                    DashboardListPanel(
                        title: "下一步",
                        symbolName: "arrow.forward.circle",
                        tint: NPTheme.green,
                        items: store.todos.filter { !$0.isCompleted }.prefix(4).map(\.title),
                        emptyText: "今天没有待办。"
                    )

                    DashboardListPanel(
                        title: "最近速记",
                        symbolName: "note.text",
                        tint: NPTheme.rose,
                        items: store.notes.prefix(4).map(\.content),
                        emptyText: "还没有速记。"
                    )
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct TodoModuleView: View {
    @ObservedObject var store: AppStore
    @State private var draft = ""

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "待办",
                    subtitle: "回车添加，点圆圈完成",
                    symbolName: "checklist",
                    tint: NPTheme.green
                )

                HStack(spacing: 8) {
                    TextField("添加一个任务", text: $draft)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.09), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onSubmit(addTodo)

                    SmallActionButton(symbolName: "plus", accent: NPTheme.green, help: "添加", action: addTodo)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedTodos) { item in
                            HStack(spacing: 8) {
                                Button {
                                    store.toggleTodo(item.id)
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isCompleted ? .green : .white.opacity(0.70))
                                }
                                .buttonStyle(.plain)

                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                    .foregroundStyle(item.isCompleted ? .white.opacity(0.42) : .white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    store.deleteTodo(item.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.white.opacity(0.50))
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .panelRow()
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var sortedTodos: [TodoItem] {
        store.todos.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private func addTodo() {
        store.addTodo(title: draft)
        draft = ""
    }
}

struct TimerModuleView: View {
    @ObservedObject var store: AppStore
    @ObservedObject var timerModel: PomodoroModel

    var body: some View {
        ModuleContainer {
            VStack(spacing: 18) {
                ModuleHeader(
                    title: "专注计时",
                    subtitle: "一个小而安静的番茄钟",
                    symbolName: "timer",
                    tint: NPTheme.amber
                )

                Picker("模式", selection: phaseBinding) {
                    ForEach(PomodoroPhase.allCases, id: \.self) { phase in
                        Text(phase.title).tag(phase)
                    }
                }
                .pickerStyle(.segmented)

                Text(timerModel.remainingText)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()

                ProgressView(value: timerModel.progress)
                    .progressViewStyle(.linear)
                    .tint(NPTheme.amber)

                HStack {
                    Button(timerModel.isRunning ? "暂停" : "开始") {
                        timerModel.startPause()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("重置") {
                        timerModel.reset()
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Stepper("专注 \(store.settings.pomodoroFocusMinutes)m", value: store.binding(\.pomodoroFocusMinutes), in: 1...180)
                    Stepper("休息 \(store.settings.pomodoroBreakMinutes)m", value: store.binding(\.pomodoroBreakMinutes), in: 1...60)
                }
                .font(.system(size: 12))
            }
        }
    }

    private var phaseBinding: Binding<PomodoroPhase> {
        Binding(
            get: { timerModel.phase },
            set: { timerModel.switchPhase($0) }
        )
    }
}

struct LauncherModuleView: View {
    @ObservedObject var store: AppStore

    private let columns = [
        GridItem(.adaptive(minimum: 88), spacing: 10)
    ]

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ModuleHeader(
                        title: "快捷启动",
                        subtitle: "常用 App 放在顶部",
                        symbolName: "app",
                        tint: NPTheme.rose
                    )
                    Spacer()
                    SmallActionButton(symbolName: "plus", accent: NPTheme.rose, help: "添加 App", action: pickApplication)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.launchItems) { item in
                            VStack(spacing: 8) {
                                Button {
                                    store.launchApp(item)
                                } label: {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.path))
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }
                                .buttonStyle(.plain)

                                Text(item.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Button {
                                    store.deleteLaunchItem(item.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.white.opacity(0.45))
                            }
                            .padding(10)
                            .panelRow()
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func pickApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            store.addLaunchApp(url: url)
        }
    }
}

struct FileShelfModuleView: View {
    @ObservedObject var store: AppStore
    @State private var isTargeted = false

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ModuleHeader(
                        title: "文件暂存",
                        subtitle: "拖进来，等会儿再拿走",
                        symbolName: "folder",
                        tint: NPTheme.cyan
                    )
                    Spacer()
                    if !store.shelfItems.isEmpty {
                        Button("清空") {
                            store.clearShelf()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isTargeted ? .blue : .white.opacity(0.22), style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                    .background(.white.opacity(isTargeted ? 0.12 : 0.04))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 24))
                            Text("把文件或 App 拖到这里")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.74))
                    }
                    .frame(height: 92)
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.shelfItems) { item in
                            fileRow(item)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func fileRow(_ item: ShelfItem) -> some View {
        let url = URL(fileURLWithPath: item.path)
        return HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.path))
                .resizable()
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(DateFormatters.shortDateTime.string(from: item.addedAt))
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            Button {
                store.revealInFinder(item)
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.plain)

            Button {
                store.deleteShelfItem(item.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .panelRow()
        .onDrag {
            NSItemProvider(object: url as NSURL)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { continue }
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let data = item as? Data
                let url = data.flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                DispatchQueue.main.async {
                    if let url {
                        if url.pathExtension.lowercased() == "app" {
                            store.addLaunchApp(url: url)
                        } else {
                            store.addShelfItems(urls: [url])
                        }
                    }
                }
            }
        }
        return accepted
    }
}

struct NotesModuleView: View {
    @ObservedObject var store: AppStore
    @State private var draft = ""

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "速记",
                    subtitle: "临时想法先收住",
                    symbolName: "note.text",
                    tint: NPTheme.rose
                )

                TextEditor(text: $draft)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(height: 92)

                HStack {
                    Spacer()
                    Button {
                        store.addNote(draft)
                        draft = ""
                    } label: {
                        Label("保存", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.notes) { note in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.content)
                                    .font(.system(size: 13))
                                    .lineLimit(3)
                                HStack {
                                    Text(DateFormatters.shortDateTime.string(from: note.createdAt))
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.48))
                                    Spacer()
                                    Button("转待办") {
                                        store.convertNoteToTodo(note)
                                    }
                                    .controlSize(.small)
                                    Button {
                                        store.deleteNote(note.id)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(10)
                            .panelRow()
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

struct SystemModuleView: View {
    @State private var snapshot = SystemSampler.snapshot()

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 16) {
                ModuleHeader(
                    title: "系统",
                    subtitle: "只放必要状态，不抢注意力",
                    symbolName: "cpu",
                    tint: NPTheme.green
                )

                HStack(spacing: 10) {
                    SummaryTile(title: "电源", value: snapshot.batteryText, symbolName: "battery.100", tint: NPTheme.green)
                    SummaryTile(title: "CPU", value: snapshot.cpuText, symbolName: "cpu", tint: NPTheme.amber)
                }
                HStack(spacing: 10) {
                    SummaryTile(title: "内存", value: snapshot.memoryText, symbolName: "memorychip", tint: NPTheme.cyan)
                    SummaryTile(title: "网络", value: snapshot.networkText, symbolName: "network", tint: NPTheme.rose)
                }

                Spacer()
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            snapshot = SystemSampler.snapshot()
        }
    }
}

struct ClipboardModuleView: View {
    @State private var recentText = ""

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 14) {
                ModuleHeader(
                    title: "剪贴板",
                    subtitle: "先读当前文本，历史稍后接入",
                    symbolName: "doc.on.clipboard",
                    tint: NPTheme.amber
                )

                Button {
                    recentText = NSPasteboard.general.string(forType: .string) ?? ""
                } label: {
                    Label("读取当前文本", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderedProminent)

                Text(recentText.isEmpty ? "No text captured yet." : recentText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .panelRow()

                Spacer()
            }
        }
    }
}

struct InlineSettingsModuleView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 14) {
                ModuleHeader(
                    title: "小岛设置",
                    subtitle: "先调最常用的几个参数",
                    symbolName: "gearshape",
                    tint: NPTheme.rose
                )
                Toggle("悬停展开", isOn: store.binding(\.expandOnHover))
                Toggle("显示模块图标", isOn: store.binding(\.showModuleIcons))
                HStack {
                    Text("紧凑宽度")
                    Slider(value: store.binding(\.compactWidth), in: 220...420, step: 1)
                    Text("\(Int(store.settings.compactWidth))")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                }
                HStack {
                    Text("展开宽度")
                    Slider(value: store.binding(\.expandedWidth), in: 520...980, step: 1)
                    Text("\(Int(store.settings.expandedWidth))")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                }
                Spacer()
            }
            .font(.system(size: 13))
        }
    }
}

struct PlaceholderModuleView: View {
    let title: String
    let symbolName: String
    let message: String

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.72))
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
    }
}

struct SummaryTile: View {
    let title: String
    let value: String
    let symbolName: String
    var tint: Color = NPTheme.cyan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbolName)
                    .foregroundStyle(tint)
                Text(title)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.58))

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .panelRow()
    }
}

struct DashboardListPanel: View {
    let title: String
    let symbolName: String
    let tint: Color
    let items: [String]
    let emptyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: symbolName)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            if items.isEmpty {
                Text(emptyText)
                    .foregroundStyle(NPTheme.mutedText)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text(item)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .panelRow()
    }
}

struct ModuleContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
