import Foundation

enum IslandModuleKind: String, Codable, CaseIterable, Identifiable {
    case dashboard
    case todos
    case timer
    case launchers
    case files
    case notes
    case system
    case calendar
    case clipboard
    case weather
    case ai
    case music
    case camera
    case shortcuts
    case settings

    var id: String { rawValue }

    static let defaultEnabled: [IslandModuleKind] = [
        .dashboard,
        .todos,
        .timer,
        .launchers,
        .files,
        .notes,
        .system,
        .clipboard,
        .settings
    ]

    static var defaultEnabledIDs: [String] {
        defaultEnabled.map(\.rawValue)
    }

    var title: String {
        switch self {
        case .dashboard: return "总览"
        case .todos: return "待办"
        case .timer: return "专注"
        case .launchers: return "启动"
        case .files: return "文件"
        case .notes: return "速记"
        case .system: return "系统"
        case .calendar: return "日程"
        case .clipboard: return "剪贴板"
        case .weather: return "天气"
        case .ai: return "AI"
        case .music: return "音乐"
        case .camera: return "镜子"
        case .shortcuts: return "快捷指令"
        case .settings: return "设置"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: return "rectangle.3.group"
        case .todos: return "checklist"
        case .timer: return "timer"
        case .launchers: return "app"
        case .files: return "folder"
        case .notes: return "note.text"
        case .system: return "cpu"
        case .calendar: return "calendar"
        case .clipboard: return "doc.on.clipboard"
        case .weather: return "cloud.sun"
        case .ai: return "sparkles"
        case .music: return "music.note"
        case .camera: return "camera.fill"
        case .shortcuts: return "bolt.heart"
        case .settings: return "gearshape"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var compactWidth: Double = 288
    var compactHeight: Double = 36
    var expandedWidth: Double = 720
    var expandedHeight: Double = 430
    var expandOnHover: Bool = true
    var showOnAllDisplays: Bool = false
    var hideInFullscreen: Bool = false
    var showModuleIcons: Bool = true
    var hoverDelay: Double = 0.08
    var activeModuleRawValue: String = IslandModuleKind.dashboard.rawValue
    var enabledModuleIDs: [String] = IslandModuleKind.defaultEnabledIDs
    var moduleOrderIDs: [String] = IslandModuleKind.allCases.map(\.rawValue)
    var pomodoroFocusMinutes: Int = 25
    var pomodoroBreakMinutes: Int = 5
    var weatherAPIKey: String = ""
    var weatherCity: String = "Beijing"
    var weatherRefreshMinutes: Int = 30
    var aiAPIKey: String = ""
    var aiBaseURL: String = "https://api.openai.com/v1"
    var aiModelName: String = "gpt-3.5-turbo"
    var launchAtLogin: Bool = false
    var languageRaw: String = Language.system.rawValue
}

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var notes: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct LaunchItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var path: String
    var bundleIdentifier: String = ""
    var addedAt: Date = Date()
}

struct ShelfItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var fileName: String
    var path: String
    var addedAt: Date = Date()
}

struct QuickNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var content: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct AppSnapshot: Codable {
    var settings: AppSettings = AppSettings()
    var todos: [TodoItem] = []
    var launchItems: [LaunchItem] = []
    var shelfItems: [ShelfItem] = []
    var notes: [QuickNote] = []
}

struct SystemSnapshot: Codable, Equatable {
    var batteryText: String = "Power --"
    var cpuText: String = "CPU --"
    var memoryText: String = "Memory --"
    var networkText: String = "Network --"
    var networkSpeedText: String = "↑ 0 B/s  ↓ 0 B/s"

    static let placeholder = SystemSnapshot()
}

struct WeatherData: Codable, Equatable {
    var temperature: Double = 0
    var description: String = ""
    var iconCode: String = ""
    var cityName: String = ""
    var humidity: Int = 0
    var windSpeed: Double = 0
    var feelsLike: Double = 0
    var fetchedAt: Date = Date()

    var temperatureText: String { "\(Int(temperature.rounded()))°" }
    var feelsLikeText: String { "体感 \(Int(feelsLike.rounded()))°" }
    var humidityText: String { "\(humidity)%" }
    var windText: String { String(format: "%.1fm/s", windSpeed) }

    var sfSymbolName: String {
        switch iconCode.prefix(2) {
        case "01": return "sun.max.fill"
        case "02": return "cloud.sun.fill"
        case "03", "04": return "cloud.fill"
        case "09": return "cloud.drizzle.fill"
        case "10": return "cloud.rain.fill"
        case "11": return "cloud.bolt.fill"
        case "13": return "snowflake"
        case "50": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

enum PomodoroPhase: String, Codable, CaseIterable {
    case focus
    case breakTime

    var title: String {
        switch self {
        case .focus: return "专注"
        case .breakTime: return "休息"
        }
    }
}

enum DateFormatters {
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}
