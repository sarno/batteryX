import Foundation
import AppKit
import AudioToolbox
import UserNotifications

public final class NotificationService: @unchecked Sendable {
    public static let shared = NotificationService()

    private init() {}

    private var hasBundleIdentifier: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    public func requestAuthorization() {
        guard hasBundleIdentifier else {
            print("[NotificationService] No bundle identifier (CLI context). Skipping UNUserNotificationCenter request.")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationService] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    public func postNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        guard hasBundleIdentifier else {
            // When run as bare CLI/runner without .app bundle, use osascript or print fallback
            deliverScriptNotification(title: title, body: body)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to post notification: \(error.localizedDescription)")
            }
        }
    }

    private func deliverScriptNotification(title: String, body: String) {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    public func playAttentionSound() {
        if let sound = NSSound(named: "Sosumi") {
            sound.play()
        } else {
            AudioServicesPlaySystemSound(1005)
        }
    }

    public func playUrgentSound() {
        if let sound = NSSound(named: "Basso") {
            sound.play()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
        }
    }
}
