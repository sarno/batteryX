import Foundation
import IOKit.ps

public final class BatteryMonitor: @unchecked Sendable {
    public static let shared = BatteryMonitor()

    public typealias BatteryUpdateHandler = @Sendable (BatteryInfo) -> Void
    private var onUpdateHandler: BatteryUpdateHandler?
    private var runLoopSource: CFRunLoopSource?
    private let lock = NSLock()

    private init() {}

    /// Start listening to IOKit battery events on the current/main RunLoop without polling
    public func startMonitoring(onUpdate: @escaping BatteryUpdateHandler) {
        lock.lock()
        self.onUpdateHandler = onUpdate
        lock.unlock()

        // Initial snapshot
        let currentSnapshot = currentBatteryInfo()
        onUpdate(currentSnapshot)

        // Event-driven run loop source
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let source = IOPSNotificationCreateRunLoopSource({ info in
            guard let info = info else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(info).takeUnretainedValue()
            let updated = monitor.currentBatteryInfo()
            monitor.notify(updated)
        }, context).takeRetainedValue()

        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    public func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        lock.lock()
        onUpdateHandler = nil
        lock.unlock()
    }

    private func notify(_ info: BatteryInfo) {
        lock.lock()
        let handler = onUpdateHandler
        lock.unlock()
        handler?(info)
    }

    /// Read raw IOKit power source snapshot
    public func currentBatteryInfo() -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryInfo()
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // Only inspect internal battery
            if let type = description[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
                let percentage = maxCapacity > 0 ? Int((Double(currentCapacity) / Double(maxCapacity)) * 100) : currentCapacity

                let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
                let powerSourceState = description[kIOPSPowerSourceStateKey] as? String
                let isPluggedIn = (powerSourceState == kIOPSACPowerValue)

                let timeRemaining = description[kIOPSTimeToEmptyKey] as? Int
                // If value is negative (-1 or -2), it means calculating or plugged in
                let validTimeRemaining = (timeRemaining != nil && timeRemaining! > 0) ? timeRemaining : nil

                return BatteryInfo(
                    currentPercentage: percentage,
                    isCharging: isCharging,
                    isPluggedIn: isPluggedIn,
                    timeRemainingMinutes: validTimeRemaining,
                    cycleCount: nil,
                    temperatureCelsius: nil,
                    maxCapacityPercentage: maxCapacity
                )
            }
        }

        return BatteryInfo()
    }
}
