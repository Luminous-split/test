import SwiftUI

@main
struct NotificationInboxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationStore.shared)
        }
        .onChange(of: scenePhase) { phase in
            // Pick up anything that arrived while the app was in the background.
            if phase == .active {
                NotificationStore.shared.refresh()
            }
        }
    }
}
