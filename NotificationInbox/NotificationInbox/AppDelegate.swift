import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: Remote push registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in NotificationStore.shared.deviceToken = token }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in NotificationStore.shared.pushError = error.localizedDescription }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// Notification arrived while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            NotificationStore.shared.add(notification)
            let speaker = Speaker.shared
            if speaker.autoRead {
                // Speak with the app's voice and mute the notification sound so it isn't read twice.
                speaker.speak(ReceivedNotification(notification).spokenText)
                completionHandler([.banner, .list, .badge])
            } else {
                completionHandler([.banner, .list, .sound, .badge])
            }
        }
    }

    /// User tapped a notification (app may have been in the background or killed).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in NotificationStore.shared.add(response.notification) }
        completionHandler()
    }
}
