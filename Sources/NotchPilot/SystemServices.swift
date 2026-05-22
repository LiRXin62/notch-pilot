import AppKit
import Foundation
import IOKit.ps
import Darwin.Mach
import Network
@preconcurrency import UserNotifications

@MainActor
final class NotificationService {
    private var didRequestAuthorization = false
    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    func requestAuthorizationIfNeeded() {
        guard canUseUserNotifications else { return }
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func notify(title: String, body: String) {
        guard canUseUserNotifications else {
            NSSound.beep()
            print("NotchPilot notification: \(title) - \(body)")
            return
        }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType = "未知"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "蜂窝"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "有线"
                } else if path.status == .satisfied {
                    self?.connectionType = "已连接"
                } else {
                    self?.connectionType = "未连接"
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}

@MainActor
enum SystemSampler {
    private static var previousCPUInfo: host_cpu_load_info_data_t?
    static let networkMonitor = NetworkMonitor()

    static func startNetworkMonitoring() {
        networkMonitor.start()
    }

    static func snapshot() -> SystemSnapshot {
        SystemSnapshot(
            batteryText: batteryText(),
            cpuText: cpuText(),
            memoryText: memoryText(),
            networkText: networkMonitor.isConnected ? "\(networkMonitor.connectionType) 已连接" : "未连接"
        )
    }

    private static func batteryText() -> String {
        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
            let source = sources.first,
            let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return "Power --"
        }

        let current = description[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int ?? 0
        let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
        let percent = maxCapacity > 0 ? Int((Double(current) / Double(maxCapacity)) * 100.0) : 0
        let sourceState = description[kIOPSPowerSourceStateKey as String] as? String ?? ""
        if sourceState == kIOPSACPowerValue as String {
            return isCharging ? "Charging \(percent)%" : "AC \(percent)%"
        }
        return "Battery \(percent)%"
    }

    private static func cpuText() -> String {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "CPU --" }

        defer { previousCPUInfo = info }
        guard let previous = previousCPUInfo else { return "CPU --" }
        let user = Double(info.cpu_ticks.0 - previous.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1 - previous.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2 - previous.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3 - previous.cpu_ticks.3)
        let total = user + system + idle + nice
        guard total > 0 else { return "CPU --" }
        let active = (user + system + nice) / total
        return "CPU \(Int(active * 100.0))%"
    }

    private static func memoryText() -> String {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), reboundPointer, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "Memory --" }
        let megabytes = info.phys_footprint / 1024 / 1024
        return "Memory \(megabytes)MB"
    }
}

@MainActor
final class WeatherService: ObservableObject {
    @Published var data: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var refreshTask: Task<Void, Never>?

    func fetch(apiKey: String, city: String) {
        guard !apiKey.isEmpty else {
            errorMessage = "请先在设置中配置 API Key"
            return
        }
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.performFetch(apiKey: apiKey, city: city)
        }
    }

    func cancelRefresh() {
        refreshTask?.cancel()
    }

    private func performFetch(apiKey: String, city: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "zh_cn")
        ]

        guard let url = components.url else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "URL 构造失败"
            }
            return
        }

        do {
            let (responseData, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200 else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = statusCode == 401 ? "API Key 无效" : "请求失败 (\(statusCode))"
                }
                return
            }

            let decoded = try JSONDecoder().decode(OWMResponse.self, from: responseData)
            await MainActor.run {
                self.data = WeatherData(
                    temperature: decoded.main.temp,
                    description: decoded.weather.first?.description ?? "",
                    iconCode: decoded.weather.first?.icon ?? "",
                    cityName: decoded.name,
                    humidity: decoded.main.humidity,
                    windSpeed: decoded.wind.speed,
                    feelsLike: decoded.main.feels_like,
                    fetchedAt: Date()
                )
                self.isLoading = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

private struct OWMResponse: Decodable {
    struct Weather: Decodable {
        let description: String
        let icon: String
    }
    struct Main: Decodable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
    }
    struct Wind: Decodable {
        let speed: Double
    }
    let weather: [Weather]
    let main: Main
    let wind: Wind
    let name: String
}
