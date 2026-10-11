import Foundation
import AppKit
import AudioToolbox
import UserNotifications

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationService()

    private override init() {
        super.init()
        if hasBundleIdentifier {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    private var hasBundleIdentifier: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    public func requestAuthorization() {
        guard hasBundleIdentifier else {
            print("[NotificationService] No bundle identifier (CLI context). Skipping UNUserNotificationCenter request.")
            return
        }
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationService] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    // Ensures notification banner and sound are presented even when app is active
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(macOS 14.0, *) {
            completionHandler([.banner, .sound, .list, .badge])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    public func postNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        playSound: Bool = true,
        soundName: String = "Sosumi"
    ) {
        // Guaranteed audible alert playback directly via audio hardware
        if playSound {
            playSoundEffect(named: soundName)
        }

        guard hasBundleIdentifier else {
            // When run as bare CLI/runner without .app bundle, use osascript fallback with sound
            deliverScriptNotification(title: title, body: body, soundName: soundName)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to post notification: \(error.localizedDescription)")
            }
        }
    }

    private func deliverScriptNotification(title: String, body: String, soundName: String = "Sosumi") {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\" sound name \"\(soundName)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    /// Plays a sound effect using multiple fallback layers (NSSound -> afplay -> AudioServices)
    public func playSoundEffect(named: String = "Sosumi") {
        DispatchQueue.main.async {
            // 1. Try NSSound
            if let sound = NSSound(named: NSSound.Name(named)) {
                sound.volume = 1.0
                if sound.play() {
                    return
                }
            }

            // 2. Direct playback via macOS afplay utility
            let soundPath = "/System/Library/Sounds/\(named).aiff"
            if FileManager.default.fileExists(atPath: soundPath) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
                process.arguments = ["-v", "1.0", soundPath]
                try? process.run()
                return
            }

            // 3. Fallback to AudioServices system alert sound
            AudioServicesPlaySystemSound(1005)
        }
    }

    public func playAttentionSound() {
        playSoundEffect(named: "Sosumi")
    }

    public func playUrgentSound() {
        playSoundEffect(named: "Basso")
    }
}
