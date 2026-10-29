import Foundation
import UIKit
import UserNotifications

struct ReceivedNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let body: String
    let date: Date
    let userInfo: String

    init(_ notification: UNNotification) {
        let content = notification.request.content
        id = notification.request.identifier
        title = content.title
        subtitle = content.subtitle
        body = content.body
        date = notification.date
        userInfo = content.userInfo.isEmpty ? "" : String(describing: content.userInfo)
    }
}

/// Holds received notifications in memory only.
/// Nothing is written to disk or a database: data is gone when the app process ends.
@MainActor
final class NotificationStore: ObservableObject {
    static let shared = NotificationStore()

    @Published private(set) var items: [ReceivedNotification] = []
    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    @Published var pushError: String?

    private let center = UNUserNotificationCenter.current()

    func add(_ notification: UNNotification) {
        let item = ReceivedNotification(notification)
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        items.sort { $0.date > $1.date }
    }

    /// Re-checks permission and imports notifications still shown in Notification Center
    /// (covers ones that arrived while the app was in the background).
    func refresh() {
        Task {
            authorization = await center.notificationSettings().authorizationStatus
            for notification in await center.deliveredNotifications() {
                add(notification)
            }
        }
    }

    func requestPermission() {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            refresh()
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Schedules a local notification so the app can be tested without a push server.
    func sendTestNotification(after seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "Test notification"
        content.body = "Sent at \(Date().formatted(date: .omitted, time: .standard))"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
    }

    func clear() {
        items.removeAll()
        center.removeAllDeliveredNotifications()
    }
}
