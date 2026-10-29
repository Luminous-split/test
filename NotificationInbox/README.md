# Notification Inbox (iOS)

A minimal SwiftUI app that receives notifications, keeps them **in memory only** and **reads them aloud**.
It uses no database, no Core Data and no UserDefaults. The list disappears when the app is closed
(swiped away) or killed by iOS. The only files it writes are short spoken-audio clips, which are deleted after an hour.

> **iOS limitation:** iOS apps can only see **their own** notifications. Apple does not let any app
> read notifications from other apps (WhatsApp, Mail, …). To have those read aloud, use Siri's built-in
> **Announce Notifications** (see [Way 4](#4-built-in-siri-announce-notifications-zero-code)).

## The ways it speaks

| # | When | How | Needs |
|---|---|---|---|
| 1 | App open | Reads each new notification aloud with the system voice. Tap a row to repeat it, or tap **Read All Aloud** | nothing |
| 2 | App closed, hands-free | *"Hey Siri, read my notifications in Notification Inbox"*. Siri reads the latest ones and the app stays closed | nothing |
| 3 | App closed, phone in pocket | The **notification sound is the spoken text**. The app turns the text into speech, saves it as a `.caf` clip and uses that clip as the notification's sound | free account for local/test notifications, paid account for remote push |
| 4 | Any app, with AirPods/CarPlay | iOS's own Siri **Announce Notifications** | AirPods/Beats, CarPlay or supported hearing aids |

### Why Way 2 works without a database
iOS already keeps delivered notifications in Notification Center. The Siri intent
(`ReadNotificationsIntent`) asks `UNUserNotificationCenter.deliveredNotifications()` for them and
returns them as dialog, which Siri speaks. Notification Center acts as the temporary store.

### Siri phrases (registered automatically, no Shortcuts setup)
- "Read my notifications in Notification Inbox"
- "Read Notification Inbox"
- "What's new in Notification Inbox"
- "Clear Notification Inbox"

Apple requires the app name in the phrase. To say only *"Hey Siri, read notifications"*, open the
**Shortcuts** app, add the **Read My Notifications** action, and name the shortcut `Read notifications`.
Siri runs shortcuts by their name. You can also add the action to the **Action button**, Back Tap or the Lock Screen.

### How Way 3 works
Way 3 makes the notification read itself out with no headphones and the app closed:
- **Test notifications:** before scheduling, the app renders the text with
  `AVSpeechSynthesizer.write(...)` to `Library/Sounds/spoken-<id>.caf`. It then sets
  `content.sound = UNNotificationSound(named:)`.
- **Remote push:** the `SpeakService` notification service extension does the same for every push
  sent with `"mutable-content": 1`, before iOS shows it. Add `"speak": false` to a payload to skip speaking.
- Notification sounds are capped at 30 seconds, so the text is cut at about 250 characters.
- The ring/silent switch applies: a silenced phone shows the banner without speaking.

## Requirements

- A Mac with **Xcode 15+**
- An iPhone or simulator with **iOS 17+**
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Installation

### Option A — XcodeGen (fastest)

```bash
cd NotificationInbox
```

```bash
brew install xcodegen
```

With a free Apple ID (Ways 1–4, with test notifications for Way 3):

```bash
xcodegen generate
```

With a paid developer account (adds remote push plus the SpeakService extension):

```bash
xcodegen generate --spec project-push.yml
```

```bash
open NotificationInbox.xcodeproj
```

### Option B — Plain Xcode, without extra tools

1. In Xcode, choose **File ▸ New ▸ Project ▸ iOS ▸ App**.
   Name it `NotificationInbox`, set Interface to **SwiftUI** and Storage to **None**. Set the minimum deployment to iOS 17.
2. Delete the generated `ContentView.swift` and `NotificationInboxApp.swift`.
3. Drag all `.swift` files from `NotificationInbox/` and `Shared/` into the app target (tick "Copy items if needed").
4. Optional, needs a paid account: choose **File ▸ New ▸ Target ▸ Notification Service Extension** and name it `SpeakService`.
   Replace its `NotificationService.swift` with the one in `SpeakService/`. Also add `Shared/SpokenSound.swift` to the extension target.
   Then add the **App Groups** capability with `group.com.example.NotificationInbox` to **both** targets,
   and add **Push Notifications** to the app.

### Run it on your iPhone

1. Select the **NotificationInbox** target and open **Signing & Capabilities**.
2. Pick your **Team** and change the Bundle Identifier to something unique,
   e.g. `com.yourname.NotificationInbox`. If you use the push setup, also change the extension to
   `com.yourname.NotificationInbox.SpeakService`. Change the app group in both targets and in
   `Shared/SpokenSound.swift` (`appGroup`) to match.
3. Connect your iPhone, select it as the run destination and press **⌘R**.
4. First run with a free account: on the iPhone, open **Settings ▸ General ▸ VPN & Device Management**
   and trust your developer certificate. If asked, turn on **Settings ▸ Privacy & Security ▸ Developer Mode**.
5. In the app, tap **Allow Notifications**.
6. Try each way:
   - Way 1: tap **Send Test Notification (5s)** and stay in the app. It speaks the notification.
   - Way 3: tap it again and lock the phone right away. The notification speaks itself (ringer must be on).
   - Way 2: with the app closed, say *"Hey Siri, read my notifications in Notification Inbox"*.
     Siri phrases can take a minute to register after the first install.

> Apps signed with a free Apple ID expire after 7 days. Run the app again from Xcode to reinstall it.

## 4. Built-in Siri "Announce Notifications" (zero code)

This works for this app **and every other app**:
1. Open **Settings ▸ Notifications ▸ Announce Notifications** (also under **Settings ▸ Siri**) and turn it on.
2. Turn on **Headphones** and/or **CarPlay**.
3. Scroll to an app, such as Notification Inbox or WhatsApp, enable it and choose **All Notifications**.
   The default is Time Sensitive & Direct Messages only.

Siri then reads incoming notifications into your AirPods or car, and you can reply by voice.
Apple only offers this through headphones, CarPlay or hearing aids, not the iPhone speaker.

## Remote push payload example

```json
{
  "aps": {
    "alert": { "title": "Mom", "body": "Dinner is ready" },
    "sound": "default",
    "mutable-content": 1
  }
}
```

`mutable-content: 1` wakes `SpeakService`, which replaces `"default"` with the spoken clip.
To send a test push, use your APNs key or Apple's Push Notifications Console at
https://icloud.developer.apple.com/dashboard/notifications. The device token is shown in the app.

### Simulator push test

Create `test.apns` with this content:

```json
{ "Simulator Target Bundle": "com.example.NotificationInbox",
  "aps": { "alert": { "title": "Hello", "body": "From simctl" }, "mutable-content": 1 } }
```

Then send it:

```bash
xcrun simctl push booted com.example.NotificationInbox test.apns
```

## Files

| File | Purpose |
|---|---|
| `NotificationInbox/NotificationInboxApp.swift` | App entry. Refreshes the list when the app becomes active |
| `NotificationInbox/AppDelegate.swift` | Notification delegate (foreground and tap), auto-read, APNs token |
| `NotificationInbox/NotificationStore.swift` | In-memory list (`@Published` array), test notifications, Read All |
| `NotificationInbox/Speaker.swift` | In-app text-to-speech (`AVSpeechSynthesizer`) |
| `NotificationInbox/SiriIntents.swift` | Siri / Shortcuts intents: Read and Clear |
| `NotificationInbox/ContentView.swift` | UI |
| `Shared/SpokenSound.swift` | Text to temporary `.caf` clip used as the notification sound |
| `SpeakService/NotificationService.swift` | Push extension that makes remote pushes speak |
| `project.yml` / `project-push.yml` | XcodeGen specs (free / paid account) |
