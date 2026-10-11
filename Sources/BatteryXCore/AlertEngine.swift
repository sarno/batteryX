import Foundation

public final class AlertEngine: @unchecked Sendable {
    public static let shared = AlertEngine()

    public var config: BatteryXConfig
    private var hasFiredWarningAlert: Bool = false
    private var hasFiredUrgentAlert: Bool = false
    private var lastWarningAlertTimestamp: Date?
    private var lastUrgentAlertTimestamp: Date?
    private var lastWarningPercentage: Int?
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
            lastWarningAlertTimestamp = nil
            lastUrgentAlertTimestamp = nil
            lastWarningPercentage = nil
            return
        }

        // We are on Battery Power (Discharging)
        let level = battery.currentPercentage
        let now = Date()

        // Level 1: Warning threshold (Default 20%)
        if level <= config.warningThresholdPercentage && level > config.urgentThresholdPercentage {
            let shouldRepeat: Bool
            if let last = lastWarningAlertTimestamp {
                // Repeat reminder every 120 seconds (2 minutes) OR if battery percentage dropped by at least 2%
                let timeElapsed = now.timeIntervalSince(last) >= 120.0
                let percentageDropped = (lastWarningPercentage ?? level) - level >= 2
                shouldRepeat = timeElapsed || percentageDropped
            } else {
                shouldRepeat = true
            }

            if !hasFiredWarningAlert || shouldRepeat {
                hasFiredWarningAlert = true
                lastWarningAlertTimestamp = now
                lastWarningPercentage = level

                notificationService.postNotification(
                    title: "⚠️ BatteryX: Peringatan Baterai Lemah (\(level)%)",
                    body: "Baterai tersisa \(level)%. Segera colok charger 96W Anda untuk mencegah penurunan daya kritis!",
                    identifier: "batteryx.warning",
                    playSound: config.isSoundAlertEnabled,
                    soundName: "Sosumi"
                )
            }
        }

        // Level 2: Urgent threshold (Default 10%)
        if level <= config.urgentThresholdPercentage {
            let shouldRepeat: Bool
            if let last = lastUrgentAlertTimestamp {
                // Repeat urgent alert every 45 seconds
                shouldRepeat = now.timeIntervalSince(last) >= 45.0
            } else {
                shouldRepeat = true
            }

            if !hasFiredUrgentAlert || shouldRepeat {
                hasFiredUrgentAlert = true
                lastUrgentAlertTimestamp = now

                notificationService.postNotification(
                    title: "🚨 BatteryX: Baterai Sangat Kritis (\(level)%)!",
                    body: "PERINGATAN: Baterai tersisa \(level)%! Jika mencapai 1%, adaptor akan kesulitan menaikkan daya saat beban berat.",
                    identifier: "batteryx.urgent",
                    playSound: config.isSoundAlertEnabled,
                    soundName: "Basso"
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
