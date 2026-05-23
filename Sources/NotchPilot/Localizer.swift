import Foundation

enum Language: String, Codable, CaseIterable, Identifiable {
    case system
    case zh
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "跟随系统 / System"
        case .zh: return "中文"
        case .en: return "English"
        }
    }
}

@MainActor
final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published var language: Language = .system

    var effectiveLanguage: String {
        if language == .system {
            return Locale.current.language.languageCode?.identifier ?? "zh"
        }
        return language.rawValue
    }

    var isEnglish: Bool { effectiveLanguage == "en" }

    func t(_ zh: String) -> String {
        if effectiveLanguage == "zh" { return zh }
        return Self.enStrings[zh] ?? zh
    }

    func t(_ zh: String, _ en: String) -> String {
        if effectiveLanguage == "zh" { return zh }
        return en
    }

    static let enStrings: [String: String] = [
        // MARK: - General
        "设置": "Settings",
        "保存": "Save",
        "取消": "Cancel",
        "清除": "Clear",
        "重试": "Retry",
        "重置": "Reset",
        "暂停": "Pause",
        "添加": "Add",
        "删除": "Delete",
        "关闭": "Close",
        "搜索…": "Search…",
        "运行": "Run",
        "刷新": "Refresh",
        "开始": "Start",

        // MARK: - Module Titles
        "总览": "Dashboard",
        "待办": "Todos",
        "专注": "Focus",
        "启动": "Launch",
        "文件": "Files",
        "速记": "Notes",
        "系统": "System",
        "日程": "Calendar",
        "剪贴板": "Clipboard",
        "天气": "Weather",
        "AI 对话": "AI Chat",
        "音乐": "Music",
        "镜子": "Mirror",
        "快捷指令": "Shortcuts",
        "快捷启动": "Quick Launch",
        "文件暂存": "File Shelf",

        // MARK: - Dashboard
        "今日总览": "Today Overview",
        "把正在发生的事收进顶部": "Keep everything at the top",
        "下一步": "Next",
        "最近速记": "Recent Notes",
        "今天没有待办。": "No todos for today.",
        "还没有速记。": "No notes yet.",

        // MARK: - Todo
        "回车添加，点圆圈完成": "Press Enter to add, tap circle to complete",
        "添加一个任务": "Add a task",
        "转待办": "Convert to Todo",
        "已转为待办": "Converted to Todo",

        // MARK: - Timer
        "专注计时": "Pomodoro Timer",
        "一个小而安静的番茄钟": "A small and quiet pomodoro",
        "休息": "Break",
        "完成": "complete",
        "休息一下吧。": "Take a short break.",
        "准备下一轮专注。": "Ready for another focus round.",

        // MARK: - Launcher
        "常用 App 放在顶部": "Pin frequently used apps",
        "添加 App": "Add App",

        // MARK: - File Shelf
        "拖进来，等会儿再拿走": "Drag in, grab later",
        "把文件或 App 拖到这里": "Drag files or apps here",

        // MARK: - Notes
        "临时想法先收住": "Capture quick thoughts",

        // MARK: - System
        "只放必要状态，不抢注意力": "Essential status only",
        "电源": "Power",
        "CPU": "CPU",
        "内存": "Memory",
        "网络": "Network",
        "未知": "Unknown",
        "已连接": "Connected",
        "未连接": "Disconnected",
        "蜂窝": "Cellular",
        "有线": "Wired",

        // MARK: - Calendar
        "需要日历权限来显示日程": "Calendar permission required",
        "需要日历权限": "Calendar access needed",
        "全天": "All day",
        "(无标题)": "(No title)",
        "授权日历访问": "Grant Calendar Access",
        "日历权限被拒绝": "Calendar access denied",
        "请在系统设置 → 隐私与安全 → 日历中授权": "Please enable in System Settings → Privacy → Calendars",
        "今日日程": "Today's Events",
        "今日无日程": "No events today",
        "提醒事项": "Reminders",
        "添加提醒…": "Add reminder…",
        "需要提醒事项权限": "Reminders permission needed",

        // MARK: - Clipboard
        "条记录": "entries",
        "显示敏感内容": "Show sensitive",
        "清空未置顶": "Clear unpinned",
        "敏感": "Sensitive",
        "刚刚": "Just now",

        // MARK: - Weather
        "需要配置 OpenWeatherMap API Key": "OpenWeatherMap API Key required",
        "前往设置 → 天气配置 API Key 和城市": "Go to Settings → Weather to configure",
        "免费申请 OpenWeatherMap API Key →": "Get free API Key →",
        "点击刷新获取天气": "Tap refresh to get weather",
        "获取天气中…": "Fetching weather…",
        "湿度": "Humidity",
        "风速": "Wind",
        "体感": "Feels like",
        "更新": "Updated",
        "秒前": "s ago",
        "分钟前": "min ago",
        "小时前": "h ago",
        "天前": "d ago",

        // MARK: - AI Chat
        "需要配置 AI API Key": "AI API Key required",
        "前往设置 → AI 配置 API Key 和模型": "Go to Settings → AI to configure",
        "免费申请 API Key →": "Get free API Key →",
        "输入消息…": "Type a message…",
        "思考中…": "Thinking…",
        "清空对话": "Clear chat",
        "请求构造失败": "Request construction failed",
        "请求失败": "Request failed",
        "URL 构造失败": "URL construction failed",
        "URL 无效": "Invalid URL",
        "请先在设置中配置 API Key": "Please configure API Key in Settings",
        "API Key 无效": "Invalid API Key",

        // MARK: - Music
        "未检测到播放": "No player detected",
        "正在检测音乐播放…": "Detecting music playback…",
        "支持 Apple Music 和 Spotify": "Supports Apple Music and Spotify",
        "播放中": "Playing",
        "已暂停": "Paused",

        // MARK: - Camera
        "前置摄像头预览": "Front camera preview",
        "摄像头已开启": "Camera active",
        "需要摄像头权限": "Camera permission required",
        "授权摄像头": "Grant Camera Access",
        "摄像头权限被拒绝": "Camera access denied",
        "请在系统设置中授权": "Please enable in System Settings",
        "点击开启前置摄像头": "Tap to open front camera",
        "开启摄像头": "Open Camera",
        "未检测到前置摄像头": "No front camera detected",

        // MARK: - Shortcuts
        "个可用": "available",
        "获取快捷指令…": "Fetching shortcuts…",
        "未找到快捷指令": "No shortcuts found",
        "获取快捷指令失败": "Failed to fetch shortcuts",
        "执行失败": "Execution failed",
        "刷新列表": "Refresh list",

        // MARK: - Settings
        "顶部效率岛设置": "Top Efficiency Island Settings",
        "通用": "General",
        "悬停展开": "Expand on hover",
        "所有显示器显示": "Show on all displays",
        "全屏应用时隐藏": "Hide in fullscreen",
        "显示模块图标": "Show module icons",
        "尺寸": "Size",
        "紧凑宽度": "Compact width",
        "紧凑高度": "Compact height",
        "展开宽度": "Expanded width",
        "展开高度": "Expanded height",
        "悬停延迟": "Hover delay",
        "模块": "Modules",
        "默认模块": "Default module",
        "模式": "Mode",
        "番茄钟": "Pomodoro",
        "城市": "City",
        "接口地址": "API Endpoint",
        "模型": "Model",
        "开机启动": "Launch at login",
        "数据": "Data",
        "导出 JSON": "Export JSON",
        "导入 JSON": "Import JSON",
        "重置 Notch Pilot?": "Reset Notch Pilot?",
        "这会清空本地待办、速记、启动项、文件暂存和设置。": "This will clear all local todos, notes, launch items, file shelf and settings.",
        "小岛设置": "Island Settings",
        "先调最常用的几个参数": "Adjust the most used parameters",
        "语言": "Language",
        "刷新间隔": "Refresh interval",
        "分钟": "min",
        "支持 OpenAI 兼容接口（OpenAI、DeepSeek、Moonshot 等）": "Supports OpenAI-compatible APIs (OpenAI, DeepSeek, Moonshot, etc.)",

        // MARK: - Island Header
        "收起": "Collapse",
        "打开专注计时": "Open Pomodoro",
        "打开待办": "Open Todos",
        "打开文件暂存": "Open File Shelf",

        // MARK: - Services
        "日历权限被拒绝，请在系统设置中授权": "Calendar permission denied, please enable in System Settings",
        "添加提醒失败": "Failed to add reminder",
        "更新提醒失败": "Failed to update reminder",
        "删除提醒失败": "Failed to delete reminder",

        // MARK: - Sample Data (Preview)
        "整理本周交付": "Organize this week's delivery",
        "回复客户消息": "Reply to client messages",
        "写一版更干净的首页": "Write a cleaner homepage",
        "把顶部岛做成真正愿意常驻的工具，而不是 demo。": "Make the top island a tool worth keeping, not just a demo.",
        "先把手感做好，再继续加模块。": "Get the feel right first, then add modules.",

        // MARK: - Status Bar Menu
        "网速": "Speed",
        "显示小岛": "Show Island",
        "导出数据…": "Export Data…",
        "导入数据…": "Import Data…",
        "退出 Notch Pilot": "Quit Notch Pilot",

        // MARK: - Login Item
        "需要自动化权限": "Automation permission required",
        "请在系统设置中授权 Notch Pilot 的自动化权限": "Please authorize Notch Pilot's automation permission in System Settings",
        "SMAppService 失败，尝试备用方案": "SMAppService failed, trying fallback",
    ]
}
