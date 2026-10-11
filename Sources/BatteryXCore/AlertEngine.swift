import Foundation

public final class AlertEngine: @unchecked Sendable {
    public static let shared = AlertEngine()

    public var config: BatteryXConfig
    private var hasFiredWarningAlert: Bool = false
    private var hasFiredUrgentAlert: Bool = false
    private var lastUrgentAlertTimestamp: Date?
    private let notificationService: NotificationService
    private let lock = NSLock()

    public init(
        config: BatteryXConfig = .default,
        notificationService: NotificationService = .shared
    ) {
        self.config = config
        self.notificationService = notificationService
    }

    /// Evaluates incoming battery state and fires tiered notifications and sounds
    public func evaluate(battery: BatteryInfo) {
        lock.lock()
        defer { lock.unlock() }

        // If charger is plugged in, reset alerts immediately
        if battery.isPluggedIn {
            hasFiredWarningAlert = false
            hasFiredUrgentAlert = false
            lastUrgentAlertTimestamp = nil
            return
        }

        // We are on Battery Power (Discharging)
        let level = battery.currentPercentage

        // Level 1: Warning threshold (Default 20%)
        if level <= config.warningThresholdPercentage && level > config.urgentThresholdPercentage {
            if !hasFiredWarningAlert {
                hasFiredWarningAlert = true
                if config.isSoundAlertEnabled {
                    notificationService.playAttentionSound()
                }
                notificationService.postNotification(
                    title: "⚠️ BatteryX: Baterai Rendah (\(level)%)",
                    body: "Baterai tersisa \(level)%. Segera colok charger 96W Anda untuk mencegah penurunan daya kritis!",
                    identifier: "batteryx.warning"
                )
            }
        }

        // Level 2: Urgent threshold (Default 10%)
        if level <= config.urgentThresholdPercentage {
            let now = Date()
            let shouldRepeat: Bool
            if let last = lastUrgentAlertTimestamp {
                shouldRepeat = now.timeIntervalSince(last) >= 60.0 // Repeat every 60 seconds
            } else {
                shouldRepeat = true
            }

            if !hasFiredUrgentAlert || shouldRepeat {
                hasFiredUrgentAlert = true
                lastUrgentAlertTimestamp = now
                if config.isSoundAlertEnabled {
                    notificationService.playUrgentSound()
                }
                notificationService.postNotification(
                    title: "🚨 BatteryX: Baterai Sangat Kritis (\(level)%)!",
                    body: "PERINGATAN: Baterai tersisa \(level)%! Jika mencapai 1%, adaptor akan kesulitan menaikkan daya saat beban berat.",
                    identifier: "batteryx.urgent"
                )
            }
        }
    }

    public func updateConfig(_ newConfig: BatteryXConfig) {
        lock.lock()
        self.config = newConfig
        lock.unlock()
    }
}
