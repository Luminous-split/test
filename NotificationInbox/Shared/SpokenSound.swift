import AVFoundation

/// Turns notification text into a short audio file that iOS plays *as the notification sound*,
/// so the notification speaks itself even when the app is closed.
/// Files are temporary: anything older than an hour is deleted on the next run.
enum SpokenSound {
    static let appGroup = "group.com.example.NotificationInbox"
    /// Notification sounds are capped at 30 seconds, so keep the text short.
    private static let maxCharacters = 250

    static func text(title: String, subtitle: String, body: String) -> String {
        let parts = [title, subtitle, body].filter { !$0.isEmpty }
        let joined = parts.isEmpty ? "New notification" : parts.joined(separator: ". ")
        return joined.count > maxCharacters ? String(joined.prefix(maxCharacters)) + "…" : joined
    }

    /// iOS looks for custom notification sounds in `Library/Sounds` of the app container
    /// or of a shared app group container (needed by the notification service extension).
    static var soundsDirectory: URL? {
        let fm = FileManager.default
        if let group = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return group.appendingPathComponent("Library/Sounds", isDirectory: true)
        }
        return fm.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Sounds", isDirectory: true)
    }

    /// Synthesizes `text` and returns the sound file name to use with `UNNotificationSound(named:)`.
    static func make(for text: String) async -> String? {
        guard let dir = soundsDirectory else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        removeOldFiles(in: dir)

        let name = "spoken-\(UUID().uuidString).caf"
        let url = dir.appendingPathComponent(name)
        let ok = await SpeechFileWriter().write(text, to: url)
        return ok ? name : nil
    }

    private static func removeOldFiles(in dir: URL) {
        let fm = FileManager.default
        let cutoff = Date().addingTimeInterval(-3600)
        let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.creationDateKey])) ?? []
        for file in files where file.lastPathComponent.hasPrefix("spoken-") {
            let created = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            if created < cutoff { try? fm.removeItem(at: file) }
        }
    }
}

/// Renders speech into a 16-bit PCM .caf file using `AVSpeechSynthesizer.write`.
private final class SpeechFileWriter {
    private let synthesizer = AVSpeechSynthesizer()
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var finished = false

    func write(_ text: String, to url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            let finish: () -> Void = { [self] in
                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                file = nil // closes the file
                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
                continuation.resume(returning: size > 0)
            }

            // Safety net in case the synthesizer never reports completion.
            DispatchQueue.global().asyncAfter(deadline: .now() + 10, execute: finish)

            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
            synthesizer.write(utterance) { [self] buffer in
                guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 { finish(); return } // empty buffer = done

                lock.lock(); defer { lock.unlock() }
                guard !finished else { return }
                if file == nil {
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: pcm.format.sampleRate,
                        AVNumberOfChannelsKey: pcm.format.channelCount,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsFloatKey: false,
                    ]
                    file = try? AVAudioFile(
                        forWriting: url,
                        settings: settings,
                        commonFormat: pcm.format.commonFormat,
                        interleaved: pcm.format.isInterleaved
                    )
                }
                try? file?.write(from: pcm)
            }
        }
    }
}
