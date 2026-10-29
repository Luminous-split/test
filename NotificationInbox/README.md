# Notification Inbox (iOS)

A minimal SwiftUI app that receives notifications and lists them **in memory only** —
no database, no Core Data, no files, no UserDefaults. Everything disappears when the app is closed
(swiped away) or killed by iOS.

## What it does

- Asks for notification permission.
- Records a notification when:
  - it arrives while the app is open (foreground),
  - you tap it from the lock screen / Notification Center,
  - the app comes back to the foreground and the notification is still in Notification Center.
- Shows the APNs device token, so you can send real pushes to it if you want.
- "Send Test Notification" schedules a local notification after 5 seconds. You can test with this
  without a push server or a paid developer account.
- "Clear" empties the list and removes delivered notifications.

> **iOS limitation:** iOS apps can only see **their own** notifications. Apple does not let any app
> read notifications from other apps (WhatsApp, Mail, …).

## Requirements

- A Mac with **Xcode 15+**
- iOS 16+ device or simulator. The simulator supports local notifications and, from Xcode 14, simulated pushes.
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Installation

### Option A — XcodeGen (fastest)

```bash
cd NotificationInbox
```

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open NotificationInbox.xcodeproj
```

### Option B — Plain Xcode, without extra tools

1. Xcode → **File ▸ New ▸ Project ▸ iOS ▸ App**.
   Name it `NotificationInbox`, Interface **SwiftUI**, Storage **None**.
2. Delete the generated `ContentView.swift` and `NotificationInboxApp.swift`.
3. Drag the four `.swift` files from `NotificationInbox/` into the project (tick "Copy items if needed").

### Run it on your iPhone

1. Select the **NotificationInbox** target ▸ **Signing & Capabilities**.
2. Pick your **Team** (a free Apple ID works) and change the Bundle Identifier to something unique,
   e.g. `com.yourname.NotificationInbox`.
3. Connect your iPhone, select it as the run destination, and press **⌘R**.
4. First run with a free account: on the iPhone open **Settings ▸ General ▸ VPN & Device Management**,
   trust your developer certificate, then open the app again. If iOS 16+ asks, turn on
   **Settings ▸ Privacy & Security ▸ Developer Mode**.
5. In the app tap **Allow Notifications**, then **Send Test Notification (5s)**. Lock the phone or
   stay in the app, and the notification shows up in the list.

> Apps signed with a free Apple ID expire after 7 days. Run the app again from Xcode to reinstall it.

## Optional: real remote push (APNs)

This needs a paid Apple Developer account.

1. **Signing & Capabilities ▸ + Capability ▸ Push Notifications**.
2. Run the app and tap **Allow Notifications**. The device token appears in the Status section.
3. Send a push with your APNs key or a tool such as the Push Notifications Console at
   https://icloud.developer.apple.com/dashboard/notifications.

Without the capability the app still works. It only shows "Remote push unavailable".

### Simulator push test

Create `test.apns` with this content:

```json
{ "Simulator Target Bundle": "com.example.NotificationInbox",
  "aps": { "alert": { "title": "Hello", "body": "From simctl" } } }
```

Then send it:

```bash
xcrun simctl push booted com.example.NotificationInbox test.apns
```

You can also drag the `.apns` file onto the simulator window.

## Files

| File | Purpose |
|---|---|
| `NotificationInboxApp.swift` | App entry. Refreshes the list when the app becomes active |
| `AppDelegate.swift` | Notification delegate (foreground and tap) plus APNs token callbacks |
| `NotificationStore.swift` | In-memory list (`@Published` array). No persistence |
| `ContentView.swift` | UI: permission status, test button, token, received list |
| `project.yml` | XcodeGen project spec |
