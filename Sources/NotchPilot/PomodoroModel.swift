import Foundation

@MainActor
final class PomodoroModel: ObservableObject {
    @Published private(set) var phase: PomodoroPhase = .focus
    @Published private(set) var isRunning = false
    @Published private(set) var remainingSeconds: Int

    private weak var store: AppStore?
    private let notificationService: NotificationService

    init(store: AppStore, notificationService: NotificationService) {
        self.store = store
        self.notificationService = notificationService
        remainingSeconds = max(1, store.settings.pomodoroFocusMinutes) * 60
    }

    var compactLabel: String {
        if isRunning {
            return remainingText
        }
        return phase.title
    }

    var remainingText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        let total = Double(totalSeconds(for: phase))
        guard total > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / total)
    }

    func startPause() {
        if !isRunning {
            notificationService.requestAuthorizationIfNeeded()
        }
        isRunning.toggle()
    }

    func reset() {
        isRunning = false
        remainingSeconds = totalSeconds(for: phase)
    }

    func switchPhase(_ next: PomodoroPhase) {
        phase = next
        isRunning = false
        remainingSeconds = totalSeconds(for: next)
    }

    func tick() {
        guard isRunning else { return }
        guard remainingSeconds > 0 else {
            completeCurrentPhase()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            completeCurrentPhase()
        }
    }

    private func completeCurrentPhase() {
        isRunning = false
        let localizer = Localizer.shared
        notificationService.notify(
            title: localizer.t(phase.title) + " " + localizer.t("完成"),
            body: phase == .focus ? localizer.t("休息一下吧。") : localizer.t("准备下一轮专注。")
        )
        phase = phase == .focus ? .breakTime : .focus
        remainingSeconds = totalSeconds(for: phase)
    }

    private func totalSeconds(for phase: PomodoroPhase) -> Int {
        guard let store else { return 25 * 60 }
        switch phase {
        case .focus:
            return max(1, store.settings.pomodoroFocusMinutes) * 60
        case .breakTime:
            return max(1, store.settings.pomodoroBreakMinutes) * 60
        }
    }
}
