import UserNotifications

/// Runs for every remote push sent with `"mutable-content": 1`, before iOS shows it.
/// Replaces the push sound with a spoken version of the notification text.
final class NotificationService: UNNotificationServiceExtension {
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var content: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        self.contentHandler = contentHandler
        self.content = content

        // Send `"speak": false` in the payload to skip speaking a push.
        if request.content.userInfo["speak"] as? Bool == false {
            deliver()
            return
        }

        Task {
            let text = SpokenSound.text(title: content.title, subtitle: content.subtitle, body: content.body)
            if let name = await SpokenSound.make(for: text) {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(name))
            }
            DispatchQueue.main.async { self.deliver() }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Out of time: show the notification with its original sound.
        deliver()
    }

    private func deliver() {
        guard let handler = contentHandler, let content else { return }
        contentHandler = nil
        handler(content)
    }
}
