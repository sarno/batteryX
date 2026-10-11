import Foundation

public struct BatteryInfo: Sendable, Codable {
    public let currentPercentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let timeRemainingMinutes: Int?
    public let cycleCount: Int?
    public let temperatureCelsius: Double?
    public let maxCapacityPercentage: Int?

    public init(
        currentPercentage: Int = 100,
        isCharging: Bool = false,
        isPluggedIn: Bool = false,
        timeRemainingMinutes: Int? = nil,
        cycleCount: Int? = nil,
        temperatureCelsius: Double? = nil,
        maxCapacityPercentage: Int? = nil
    ) {
        self.currentPercentage = currentPercentage
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.timeRemainingMinutes = timeRemainingMinutes
        self.cycleCount = cycleCount
        self.temperatureCelsius = temperatureCelsius
        self.maxCapacityPercentage = maxCapacityPercentage
    }
}

public struct BatteryXConfig: Sendable, Codable {
    public var warningThresholdPercentage: Int
    public var urgentThresholdPercentage: Int
    public var chargeLimitPercentage: Int
    public var isChargeLimiterEnabled: Bool
    public var isSoundAlertEnabled: Bool

    public static let `default` = BatteryXConfig(
        warningThresholdPercentage: 20,
        urgentThresholdPercentage: 10,
        chargeLimitPercentage: 80,
        isChargeLimiterEnabled: true,
        isSoundAlertEnabled: true
    )
}
