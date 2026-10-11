import Foundation

public final class ChargeLimiterService: @unchecked Sendable {
    public static let shared = ChargeLimiterService()

    private let smc = SMCDriver.shared
    private let bclmKey = "BCLM" // Battery Charge Limit Max
    private let lock = NSLock()

    private init() {}

    /// Read current charge limit (returns nil if not accessible or unsupported)
    public func currentChargeLimit() -> Int? {
        if let val = smc.readUint8(key: bclmKey) {
            return Int(val)
        }
        return nil
    }

    /// Set charge limit percentage (clamped strictly between 40% and 100%)
    public func setChargeLimit(percentage: Int) -> Bool {
        let clamped = max(40, min(100, percentage))
        return smc.writeUint8(key: bclmKey, value: UInt8(clamped))
    }

    /// Reset charge limit to 100% (Normal unlimited charging)
    public func resetChargeLimit() -> Bool {
        return setChargeLimit(percentage: 100)
    }
}
