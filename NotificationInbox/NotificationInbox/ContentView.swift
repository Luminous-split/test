import AppIntents
import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var store: NotificationStore
    @ObservedObject private var speaker = Speaker.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    LabeledContent("Permission", value: permissionText)
                    if store.authorization != .authorized {
                        Button("Allow Notifications") { store.requestPermission() }
                    }
                    Button("Send Test Notification (5s)") { store.sendTestNotification() }
                    if let token = store.deviceToken {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("APNs device token").font(.caption).foregroundStyle(.secondary)
                            Text(token).font(.caption2.monospaced()).textSelection(.enabled)
                        }
                    } else if let error = store.pushError {
                        Text("Remote push unavailable: \(error)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Voice") {
                    Toggle("Read aloud when received", isOn: $speaker.autoRead)
                    if speaker.isSpeaking {
                        Button("Stop Speaking", role: .destructive) { speaker.stop() }
                    } else {
                        Button("Read All Aloud") { store.readAll() }
                    }
                    SiriTipView(intent: ReadNotificationsIntent())
                }

                Section("Received (\(store.items.count)) — kept in memory only") {
                    if store.items.isEmpty {
                        Text("No notifications yet").foregroundStyle(.secondary)
                    }
                    ForEach(store.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title.isEmpty ? "(no title)" : item.title).font(.headline)
                            if !item.subtitle.isEmpty { Text(item.subtitle).font(.subheadline) }
                            if !item.body.isEmpty { Text(item.body) }
                            if !item.userInfo.isEmpty {
                                Text(item.userInfo).font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                            Text(item.date.formatted(date: .abbreviated, time: .standard))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture { speaker.speak(item.spokenText) }
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear", role: .destructive) { store.clear() }.disabled(store.items.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.refresh() } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .refreshable { store.refresh() }
            .onAppear { store.refresh() }
        }
    }

    private var permissionText: String {
        switch store.authorization {
        case .authorized: return "Allowed"
        case .denied: return "Denied (enable in Settings)"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }
}
