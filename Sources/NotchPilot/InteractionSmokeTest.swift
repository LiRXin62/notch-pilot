import Foundation

@MainActor
enum InteractionSmokeTest {
    static func run() {
        let store = AppStore(
            snapshot: AppSnapshot(),
            storageURL: URL(fileURLWithPath: "/private/tmp/notch-pilot-smoke-state.json")
        )
        let notificationService = NotificationService()
        let timerModel = PomodoroModel(store: store, notificationService: notificationService)

        assert(store.isModuleEnabled(.todos), "todos should be enabled by default")
        assert(!store.isModuleEnabled(.weather), "weather should not be enabled by default (requires API key)")

        store.setActiveModule(.todos)
        assert(store.activeModule() == .todos, "status/module buttons should be able to switch to todos")

        store.setActiveModule(.timer)
        assert(store.activeModule() == .timer, "status/module buttons should be able to switch to timer")

        store.setActiveModule(.files)
        assert(store.activeModule() == .files, "status/module buttons should be able to switch to files")

        store.addTodo(title: "smoke todo")
        assert(store.todos.count == 1, "todo add should work")
        store.toggleTodo(store.todos[0].id)
        assert(store.todos[0].isCompleted, "todo toggle should work")

        store.addNote("smoke note")
        assert(store.notes.count == 1, "note add should work")
        store.convertNoteToTodo(store.notes[0])
        assert(store.todos.count == 2, "note to todo should work")

        timerModel.startPause()
        assert(timerModel.isRunning, "timer start should work")
        timerModel.startPause()
        assert(!timerModel.isRunning, "timer pause should work")

        print("NotchPilot interaction smoke test passed")
    }
}

