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
        .onAppear {
            SystemSampler.startNetworkMonitoring()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            snapshot = SystemSampler.snapshot()
        }
    }
}

struct ClipboardModuleView: View {
    @ObservedObject var clipboardService: ClipboardService
    @State private var searchText = ""
    @State private var showSensitive = false

    var filteredEntries: [ClipboardEntry] {
        var result = clipboardService.entries
        if !searchText.isEmpty {
            result = result.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        if !showSensitive {
            result = result.filter { !$0.isSensitive }
        }
        return result
    }

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "剪贴板",
                    subtitle: "\(clipboardService.entries.count) 条记录",
                    symbolName: "doc.on.clipboard",
                    tint: NPTheme.amber
                )

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("搜索…", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredEntries) { entry in
                            clipboardRow(entry)
                        }
                    }
                }

                HStack {
                    Toggle("显示敏感内容", isOn: $showSensitive)
                        .font(.system(size: 10))
                        .toggleStyle(.checkbox)
                    Spacer()
                    Button("清空未置顶") { clipboardService.clearUnpinned() }
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                        .buttonStyle(.plain)
                }
            }
        }
        .onAppear { clipboardService.startMonitoring() }
        .onDisappear { clipboardService.stopMonitoring() }
    }

    private func clipboardRow(_ entry: ClipboardEntry) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.content)
                    .font(.system(size: 11.5))
                    .foregroundStyle(entry.isSensitive ? .white.opacity(0.38) : .white.opacity(0.82))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text(timeSince(entry.timestamp))
                        .font(.system(size: 9))
                        .foregroundStyle(NPTheme.mutedText)

                    if entry.isSensitive {
                        Text("敏感")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(NPTheme.amber)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(NPTheme.amber.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    if entry.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(NPTheme.cyan)
                    }
                }
            }

            HStack(spacing: 4) {
                Button {
                    clipboardService.togglePin(entry)
                } label: {
                    Image(systemName: entry.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Button {
                    clipboardService.copyToPasteboard(entry)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)

                Button {
                    clipboardService.delete(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .panelRow()
    }

    private func timeSince(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "刚刚" }
        if seconds < 3600 { return "\(seconds / 60)分钟前" }
        if seconds < 86400 { return "\(seconds / 3600)小时前" }
        return "\(seconds / 86400)天前"
    }
}

struct CalendarModuleView: View {
    @ObservedObject var calendarService: CalendarService
    @State private var newReminderTitle = ""

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "日程",
                    subtitle: DateFormatters.date.string(from: Date()),
                    symbolName: "calendar",
                    tint: NPTheme.green
                )

                if calendarService.authorizationStatus == .notDetermined {
                    requestAccessView
                } else if calendarService.authorizationStatus == .denied || calendarService.authorizationStatus == .restricted {
                    deniedView
                } else {
                    calendarContent
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.fetchEvents()
                calendarService.fetchReminders()
            }
        }
    }

    private var requestAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(NPTheme.amber)
            Text("需要日历权限来显示日程")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.72))
            Button("授权日历访问") {
                calendarService.requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(NPTheme.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var deniedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.5))
            Text("日历权限被拒绝")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            Text("请在系统设置 → 隐私与安全 → 日历中授权")
                .font(.system(size: 11))
                .foregroundStyle(NPTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Events section
            if !calendarService.events.isEmpty {
                Text("今日日程")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NPTheme.mutedText)

                ForEach(calendarService.events) { event in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: event.calendarColor))
                            .frame(width: 6, height: 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.88))
                                .lineLimit(1)
                            Text(event.timeRangeText)
                                .font(.system(size: 10))
                                .foregroundStyle(NPTheme.mutedText)
                        }

                        Spacer()

                        Text(event.calendarTitle)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.38))
                    }
                    .padding(8)
                    .panelRow()
                }
            } else {
                Text("今日无日程")
                    .font(.system(size: 12))
                    .foregroundStyle(NPTheme.mutedText)
                    .padding(.vertical, 8)
            }

            // Reminders section
            HStack {
                Text("提醒事项")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NPTheme.mutedText)
                Spacer()
                Button {
                    calendarService.fetchReminders()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            ForEach(calendarService.reminders.prefix(8)) { reminder in
                HStack(spacing: 8) {
                    Button {
                        calendarService.toggleReminder(reminder)
                    } label: {
                        Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(reminder.isCompleted ? NPTheme.green : .white.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(reminder.title)
                            .font(.system(size: 12))
                            .foregroundStyle(reminder.isCompleted ? .white.opacity(0.4) : .white.opacity(0.82))
                            .strikethrough(reminder.isCompleted)
                        if !reminder.dueDateText.isEmpty {
                            Text(reminder.dueDateText)
                                .font(.system(size: 9))
                                .foregroundStyle(NPTheme.mutedText)
                        }
                    }

                    Spacer()

                    Button {
                        calendarService.deleteReminder(reminder)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
                .panelRow()
            }

            // Add reminder
            HStack(spacing: 8) {
                TextField("添加提醒…", text: $newReminderTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .onSubmit {
                        guard !newReminderTitle.isEmpty else { return }
                        calendarService.addReminder(title: newReminderTitle)
                        newReminderTitle = ""
                    }
            }

            if let error = calendarService.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(NPTheme.amber)
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

struct MusicModuleView: View {
    @ObservedObject var musicService: MusicService

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 14) {
                ModuleHeader(
                    title: "音乐",
                    subtitle: musicService.nowPlaying.appName.isEmpty ? "未检测到播放" : musicService.nowPlaying.appName,
                    symbolName: "music.note",
                    tint: NPTheme.rose
                )

                if musicService.nowPlaying.isEmpty {
                    emptyView
                } else {
                    nowPlayingView
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear { musicService.startMonitoring() }
        .onDisappear { musicService.stopMonitoring() }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.3))
            Text("正在检测音乐播放…")
                .font(.system(size: 12))
                .foregroundStyle(NPTheme.mutedText)
            Text("支持 Apple Music 和 Spotify")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var nowPlayingView: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(NPTheme.rose.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                            .foregroundStyle(NPTheme.rose.opacity(0.6))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(musicService.nowPlaying.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(musicService.nowPlaying.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)

                    Text(musicService.nowPlaying.album)
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.mutedText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(musicService.nowPlaying.isPlaying ? NPTheme.green : NPTheme.amber)
                            .frame(width: 6, height: 6)
                        Text(musicService.nowPlaying.isPlaying ? "播放中" : "已暂停")
                            .font(.system(size: 10))
                            .foregroundStyle(NPTheme.mutedText)
                    }
                }

                Spacer()
            }

            // Playback controls
            HStack(spacing: 24) {
                Button {
                    musicService.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)

                Button {
                    musicService.togglePlayPause()
                } label: {
                    Image(systemName: musicService.nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    musicService.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct CameraMirrorModuleView: View {
    @ObservedObject var cameraService: CameraMirrorService

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 14) {
                ModuleHeader(
                    title: "镜子",
                    subtitle: cameraService.isRunning ? "摄像头已开启" : "前置摄像头预览",
                    symbolName: "camera.fill",
                    tint: NPTheme.cyan
                )

                if cameraService.authorizationStatus == .notDetermined {
                    requestAccessView
                } else if cameraService.authorizationStatus == .denied || cameraService.authorizationStatus == .restricted {
                    deniedView
                } else if cameraService.isRunning {
                    cameraPreview
                } else {
                    startView
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var requestAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 28))
                .foregroundStyle(NPTheme.cyan)
            Text("需要摄像头权限")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.72))
            Button("授权摄像头") {
                cameraService.requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(NPTheme.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var deniedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.5))
            Text("摄像头权限被拒绝")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            Text("请在系统设置中授权")
                .font(.system(size: 11))
                .foregroundStyle(NPTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var startView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 36))
                .foregroundStyle(NPTheme.cyan.opacity(0.6))
            Text("点击开启前置摄像头")
                .font(.system(size: 12))
                .foregroundStyle(NPTheme.mutedText)
            Button("开启摄像头") {
                cameraService.startCapture()
            }
            .buttonStyle(.borderedProminent)
            .tint(NPTheme.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var cameraPreview: some View {
        VStack(spacing: 10) {
            CameraPreviewView(cameraService: cameraService)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )

            HStack {
                Spacer()
                Button {
                    cameraService.stopCapture()
                } label: {
                    Label("关闭", systemImage: "xmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CameraPreviewView: NSViewRepresentable {
    let cameraService: CameraMirrorService

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        if let previewLayer = cameraService.getPreviewLayer() {
            previewLayer.frame = view.bounds
            previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            view.layer = previewLayer
            view.wantsLayer = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = cameraService.getPreviewLayer() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = nsView.bounds
            CATransaction.commit()
        }
    }
}

struct ShortcutsModuleView: View {
    @ObservedObject var shortcutsService: ShortcutsService

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "快捷指令",
                    subtitle: "\(shortcutsService.shortcuts.count) 个可用",
                    symbolName: "bolt.heart",
                    tint: NPTheme.amber
                )

                if shortcutsService.isLoading {
                    loadingView
                } else if shortcutsService.shortcuts.isEmpty {
                    emptyView
                } else {
                    shortcutsList
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            if shortcutsService.shortcuts.isEmpty {
                shortcutsService.fetchShortcuts()
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            Text("获取快捷指令…")
                .font(.system(size: 12))
                .foregroundStyle(NPTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.heart")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.3))
            Text("未找到快捷指令")
                .font(.system(size: 12))
                .foregroundStyle(NPTheme.mutedText)
            Button("刷新") {
                shortcutsService.fetchShortcuts()
            }
            .font(.system(size: 11))
            .foregroundStyle(NPTheme.cyan)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var shortcutsList: some View {
        VStack(spacing: 6) {
            ForEach(shortcutsService.shortcuts) { shortcut in
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.amber.opacity(0.7))

                    Text(shortcut.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(1)

                    Spacer()

                    if shortcut.isRunning {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Button {
                            shortcutsService.runShortcut(shortcut)
                        } label: {
                            Text("运行")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(NPTheme.amber)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .panelRow()
            }

            HStack {
                Spacer()
                Button("刷新列表") {
                    shortcutsService.fetchShortcuts()
                }
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
                .buttonStyle(.plain)
            }

            if let error = shortcutsService.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(NPTheme.amber)
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
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

struct WeatherModuleView: View {
    @ObservedObject var weatherService: WeatherService
    @ObservedObject var store: AppStore
    @State private var showSettings = false

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 14) {
                ModuleHeader(
                    title: "天气",
                    subtitle: weatherService.data?.cityName ?? store.settings.weatherCity,
                    symbolName: "cloud.sun",
                    tint: NPTheme.cyan
                )

                if store.settings.weatherAPIKey.isEmpty {
                    apiKeyPrompt
                } else if let data = weatherService.data {
                    weatherContent(data)
                } else if weatherService.isLoading {
                    loadingView
                } else if let error = weatherService.errorMessage {
                    errorView(error)
                } else {
                    Text("点击刷新获取天气")
                        .foregroundStyle(NPTheme.mutedText)
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            if weatherService.data == nil && !store.settings.weatherAPIKey.isEmpty {
                weatherService.fetch(apiKey: store.settings.weatherAPIKey, city: store.settings.weatherCity)
            }
        }
    }

    private var apiKeyPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("需要配置 OpenWeatherMap API Key")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(NPTheme.amber)
                Text("前往设置 → 天气配置 API Key 和城市")
                    .font(.system(size: 12))
                    .foregroundStyle(NPTheme.mutedText)
            }
            .padding(10)
            .panelRow()

            Link("免费申请 API Key →", destination: URL(string: "https://openweathermap.org/appid")!)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NPTheme.cyan)
        }
    }

    private func weatherContent(_ data: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.temperatureText)
                        .font(.system(size: 42, weight: .thin, design: .rounded))
                    Text(data.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                    Text(data.feelsLikeText)
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.mutedText)
                }

                Spacer()

                Image(systemName: data.sfSymbolName)
                    .font(.system(size: 44))
                    .foregroundStyle(NPTheme.cyan.opacity(0.85))
                    .symbolRenderingMode(.hierarchical)
            }

            HStack(spacing: 0) {
                DetailChip(icon: "humidity.fill", value: data.humidityText, label: "湿度")
                DetailChip(icon: "wind", value: data.windText, label: "风速")
                DetailChip(icon: "clock", value: timeSince(data.fetchedAt), label: "更新")
            }

            HStack {
                Spacer()
                Button {
                    weatherService.fetch(apiKey: store.settings.weatherAPIKey, city: store.settings.weatherCity)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .disabled(weatherService.isLoading)
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            Text("获取天气中…")
                .font(.system(size: 12))
                .foregroundStyle(NPTheme.mutedText)
        }
        .padding(.top, 20)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(NPTheme.amber)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Button("重试") {
                weatherService.fetch(apiKey: store.settings.weatherAPIKey, city: store.settings.weatherCity)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(NPTheme.cyan)
            .buttonStyle(.plain)
        }
        .padding(10)
        .panelRow()
    }

    private func timeSince(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "\(seconds)秒前" }
        if seconds < 3600 { return "\(seconds / 60)分钟前" }
        return "\(seconds / 3600)小时前"
    }
}

struct AIChatModuleView: View {
    @ObservedObject var chatService: AIChatService
    @ObservedObject var store: AppStore
    @State private var inputText = ""

    var body: some View {
        ModuleContainer {
            VStack(alignment: .leading, spacing: 12) {
                ModuleHeader(
                    title: "AI 对话",
                    subtitle: store.settings.aiModelName,
                    symbolName: "sparkles",
                    tint: NPTheme.rose
                )

                if store.settings.aiAPIKey.isEmpty && KeychainHelper.load(key: "aiAPIKey") == nil {
                    apiKeyPrompt
                } else {
                    chatContent
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var apiKeyPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("需要配置 AI API Key")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(NPTheme.amber)
                Text("前往设置 → AI 配置 API Key 和模型")
                    .font(.system(size: 12))
                    .foregroundStyle(NPTheme.mutedText)
            }
            .padding(10)
            .panelRow()
        }
    }

    private var chatContent: some View {
        VStack(spacing: 10) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chatService.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if chatService.isLoading && chatService.messages.last?.role != "assistant" {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("思考中…")
                                    .font(.system(size: 11))
                                    .foregroundStyle(NPTheme.mutedText)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: chatService.messages.count) {
                    if let last = chatService.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = chatService.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(NPTheme.amber)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Button("清除") { chatService.errorMessage = nil }
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.cyan)
                        .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                TextField("输入消息…", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.09), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onSubmit(sendMessage)

                if chatService.isLoading {
                    Button {
                        chatService.stopGeneration()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 30, height: 30)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                            .background(NPTheme.rose)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            HStack {
                if chatService.tokenUsage > 0 {
                    Text("Token: \(chatService.tokenUsage)")
                        .font(.system(size: 9))
                        .foregroundStyle(NPTheme.mutedText)
                }
                Spacer()
                Button("清空对话") { chatService.clearHistory() }
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .buttonStyle(.plain)
            }
        }
    }

    private func messageBubble(_ message: AIChatMessage) -> some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 40) }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(message.role == "user" ? NPTheme.rose.opacity(0.3) : .white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if message.role != "user" { Spacer(minLength: 40) }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        chatService.send(text, settings: store.settings)
    }
}

struct DetailChip: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(NPTheme.cyan.opacity(0.7))
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(NPTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
