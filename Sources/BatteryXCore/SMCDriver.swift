import Foundation
import CSMCBridge

public final class SMCDriver: @unchecked Sendable {
    public static let shared = SMCDriver()

    private let lock = NSLock()

    private init() {}

    public func open() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return smc_open()
    }

    public func close() {
        lock.lock()
        defer { lock.unlock() }
        smc_close()
    }

    /// Read 1-byte integer key (e.g., BCLM)
    public func readUint8(key: String) -> UInt8? {
        lock.lock()
        defer { lock.unlock() }
        var val: UInt8 = 0
        if smc_read_uint8(key, &val) {
            return val
        }
        return nil
    }

    /// Write 1-byte integer key (e.g. BCLM with value 80)
    public func writeUint8(key: String, value: UInt8) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return smc_write_uint8(key, value)
    }
}
