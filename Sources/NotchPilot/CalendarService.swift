import AppKit
import EventKit
import Foundation

struct CalendarEventItem: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: String

    var timeRangeText: String {
        if isAllDay { return "全天" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

struct ReminderItem: Identifiable, Equatable {
    let id: String
    let title: String
    let isCompleted: Bool
    let dueDate: Date?
    let calendarTitle: String

    var dueDateText: String {
        guard let dueDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: dueDate)
    }
}

@MainActor
final class CalendarService: ObservableObject {
    @Published var events: [CalendarEventItem] = []
    @Published var reminders: [ReminderItem] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private let eventStore = EKEventStore()

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            Task { @MainActor in
                self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if granted {
                    self?.fetchEvents()
                } else {
                    self?.errorMessage = error?.localizedDescription ?? Localizer.shared.t("日历权限被拒绝，请在系统设置中授权")
                }
            }
        }

        eventStore.requestFullAccessToReminders { [weak self] granted, _ in
            Task { @MainActor in
                if granted {
                    self?.fetchReminders()
                }
            }
        }
    }

    func fetchEvents() {
        guard authorizationStatus == .fullAccess else {
            errorMessage = Localizer.shared.t("需要日历权限")
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        events = ekEvents.map { event in
            CalendarEventItem(
                id: event.eventIdentifier,
                title: event.title ?? Localizer.shared.t("(无标题)"),
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarTitle: event.calendar.title,
                calendarColor: event.calendar.cgColor.flatMap { cgColor in
                    let color = NSColor(cgColor: cgColor) ?? .systemBlue
                    return String(format: "#%02X%02X%02X",
                                  Int(color.redComponent * 255),
                                  Int(color.greenComponent * 255),
                                  Int(color.blueComponent * 255))
                } ?? "#007AFF"
            )
        }.sorted { $0.startDate < $1.startDate }

        errorMessage = nil
    }

    func fetchReminders() {
        let calendars = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            calendars: calendars
        )

        eventStore.fetchReminders(matching: predicate) { [weak self] ekReminders in
            Task { @MainActor in
                self?.reminders = (ekReminders ?? []).map { reminder in
                    ReminderItem(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? Localizer.shared.t("(无标题)"),
                        isCompleted: reminder.isCompleted,
                        dueDate: reminder.dueDateComponents?.date,
                        calendarTitle: reminder.calendar.title
                    )
                }.sorted { a, b in
                    guard let aDate = a.dueDate else { return false }
                    guard let bDate = b.dueDate else { return true }
                    return aDate < bDate
                }
            }
        }
    }

    func addReminder(title: String) {
        guard authorizationStatus == .fullAccess else {
            errorMessage = Localizer.shared.t("需要提醒事项权限")
            return
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders()
        } catch {
            errorMessage = Localizer.shared.t("添加提醒失败") + ": \(error.localizedDescription)"
        }
    }

    func toggleReminder(_ item: ReminderItem) {
        guard let ekReminder = eventStore.calendarItem(withIdentifier: item.id) as? EKReminder else { return }
        ekReminder.isCompleted = !item.isCompleted
        do {
            try eventStore.save(ekReminder, commit: true)
            fetchReminders()
        } catch {
            errorMessage = Localizer.shared.t("更新提醒失败") + ": \(error.localizedDescription)"
        }
    }

    func deleteReminder(_ item: ReminderItem) {
        guard let ekReminder = eventStore.calendarItem(withIdentifier: item.id) as? EKReminder else { return }
        do {
            try eventStore.remove(ekReminder, commit: true)
            fetchReminders()
        } catch {
            errorMessage = Localizer.shared.t("删除提醒失败") + ": \(error.localizedDescription)"
        }
    }
}
