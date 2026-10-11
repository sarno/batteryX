import Foundation

public final class SettingsManager: ObservableObject, @unchecked Sendable {
    public static let shared = SettingsManager()

    private let defaults = UserDefaults.standard
    private let warningKey = "batteryx.warningThreshold"
    private let urgentKey = "batteryx.urgentThreshold"
    private let limitKey = "batteryx.chargeLimit"
    private let limiterEnabledKey = "batteryx.isChargeLimiterEnabled"
    private let soundEnabledKey = "batteryx.isSoundAlertEnabled"

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

    private init() {
        self.warningThreshold = defaults.object(forKey: warningKey) as? Int ?? 20
        self.urgentThreshold = defaults.object(forKey: urgentKey) as? Int ?? 10
        self.chargeLimit = defaults.object(forKey: limitKey) as? Int ?? 80
        self.isChargeLimiterEnabled = defaults.object(forKey: limiterEnabledKey) as? Bool ?? true
        self.isSoundAlertEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
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
        if isChargeLimiterEnabled {
            _ = ChargeLimiterService.shared.setChargeLimit(percentage: chargeLimit)
        } else {
            _ = ChargeLimiterService.shared.resetChargeLimit()
        }
    }
}
