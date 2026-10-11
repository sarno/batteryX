import Foundation

public final class SettingsManager: ObservableObject, @unchecked Sendable {
    public static let shared = SettingsManager()

    private let defaults = UserDefaults.standard
    private let warningKey = "batteryx.warningThreshold"
    private let urgentKey = "batteryx.urgentThreshold"
    private let limitKey = "batteryx.chargeLimit"
    private let limiterEnabledKey = "batteryx.isChargeLimiterEnabled"
    private let soundEnabledKey = "batteryx.isSoundAlertEnabled"
    private let launchAtLoginKey = "batteryx.isLaunchAtLoginEnabled"

    @Published public var warningThreshold: Int {
        didSet {
            defaults.set(warningThreshold, forKey: warningKey)
            syncAlertEngine()
        }
    }

    @Published public var urgentThreshold: Int {
        didSet {
            defaults.set(urgentThreshold, forKey: urgentKey)
            syncAlertEngine()
        }
    }

    @Published public var chargeLimit: Int {
        didSet {
            defaults.set(chargeLimit, forKey: limitKey)
            syncChargeLimiter()
        }
    }

    @Published public var isChargeLimiterEnabled: Bool {
        didSet {
            defaults.set(isChargeLimiterEnabled, forKey: limiterEnabledKey)
            syncChargeLimiter()
        }
    }

    @Published public var isSoundAlertEnabled: Bool {
        didSet {
            defaults.set(isSoundAlertEnabled, forKey: soundEnabledKey)
            syncAlertEngine()
        }
    }

    @Published public var isLaunchAtLoginEnabled: Bool {
        didSet {
            defaults.set(isLaunchAtLoginEnabled, forKey: launchAtLoginKey)
            LaunchAtLoginService.shared.setLaunchAtLogin(enabled: isLaunchAtLoginEnabled)
        }
    }

    private init() {
        self.warningThreshold = defaults.object(forKey: warningKey) as? Int ?? 20
        self.urgentThreshold = defaults.object(forKey: urgentKey) as? Int ?? 10
        self.chargeLimit = defaults.object(forKey: limitKey) as? Int ?? 80
        self.isChargeLimiterEnabled = defaults.object(forKey: limiterEnabledKey) as? Bool ?? true
        self.isSoundAlertEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true

        let savedLaunchAtLogin = defaults.object(forKey: launchAtLoginKey) as? Bool
        let initialLaunchAtLogin = savedLaunchAtLogin ?? true
        self.isLaunchAtLoginEnabled = initialLaunchAtLogin

        if savedLaunchAtLogin == nil {
            defaults.set(true, forKey: launchAtLoginKey)
            LaunchAtLoginService.shared.setLaunchAtLogin(enabled: true)
        }
    }

    public func refreshLaunchAtLoginStatus() {
        let systemStatus = LaunchAtLoginService.shared.checkCurrentStatus()
        if self.isLaunchAtLoginEnabled != systemStatus {
            self.isLaunchAtLoginEnabled = systemStatus
        }
    }

    public func syncAlertEngine() {
        let config = BatteryXConfig(
            warningThresholdPercentage: warningThreshold,
            urgentThresholdPercentage: urgentThreshold,
            chargeLimitPercentage: chargeLimit,
            isChargeLimiterEnabled: isChargeLimiterEnabled,
            isSoundAlertEnabled: isSoundAlertEnabled
        )
        AlertEngine.shared.updateConfig(config)
    }

    public func syncChargeLimiter() {
        let helperPath = HelperInstallerService.shared.targetPath

        // If privileged helper exists at /usr/local/bin/batteryx-helper, execute it!
        if FileManager.default.fileExists(atPath: helperPath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: helperPath)
            if isChargeLimiterEnabled {
                process.arguments = ["set-limit", "\(chargeLimit)"]
            } else {
                process.arguments = ["reset"]
            }
            try? process.run()
        } else {
            // Fallback in-process SMC attempt
            if isChargeLimiterEnabled {
                _ = ChargeLimiterService.shared.setChargeLimit(percentage: chargeLimit)
            } else {
                _ = ChargeLimiterService.shared.resetChargeLimit()
            }
        }
    }
}
