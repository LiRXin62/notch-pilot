import AppKit
import Foundation
import IOKit.ps
import Darwin.Mach
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
enum SystemSampler {
    private static var previousCPUInfo: host_cpu_load_info_data_t?

    static func snapshot() -> SystemSnapshot {
        SystemSnapshot(
            batteryText: batteryText(),
            cpuText: cpuText(),
            memoryText: memoryText(),
            networkText: "Network ready"
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
