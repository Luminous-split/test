import AppIntents
import UserNotifications

/// "Hey Siri, read my notifications in Notification Inbox."
/// Works with the app closed: it reads what is still in Notification Center,
/// plus anything held in memory if the app is running. No database involved.
struct ReadNotificationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Read My Notifications"
    static var description = IntentDescription("Siri reads your latest notifications aloud.")
    static var openAppWhenRun = false

    @Parameter(title: "How many", default: 5, inclusiveRange: (1, 20))
    var limit: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        let items = await MainActor.run { () -> [ReceivedNotification] in
            let store = NotificationStore.shared
            delivered.forEach(store.add)
            return store.items
        }

        guard !items.isEmpty else {
            return .result(dialog: "You have no notifications.")
        }

        let latest = items.prefix(limit)
        let lines = latest.enumerated().map { index, item in "\(index + 1). \(item.spokenText)" }
        let intro = items.count == 1 ? "You have 1 notification." : "You have \(items.count) notifications."
        let text = ([intro] + lines).joined(separator: "\n")
        return .result(dialog: "\(text)")
    }
}

struct ClearNotificationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear My Notifications"
    static var description = IntentDescription("Removes all notifications from Notification Inbox.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run { NotificationStore.shared.clear() }
        return .result(dialog: "Notifications cleared.")
    }
}

/// Registers the Siri phrases automatically, with no setup in the Shortcuts app.
/// Siri phrases from third-party apps must contain the app name.
struct InboxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ReadNotificationsIntent(),
            phrases: [
                "Read my notifications in \(.applicationName)",
                "Read \(.applicationName)",
                "What's new in \(.applicationName)",
            ],
            shortTitle: "Read Notifications",
            systemImageName: "speaker.wave.2"
        )
        AppShortcut(
            intent: ClearNotificationsIntent(),
            phrases: ["Clear \(.applicationName)", "Clear my notifications in \(.applicationName)"],
            shortTitle: "Clear Notifications",
            systemImageName: "trash"
        )
    }
}
