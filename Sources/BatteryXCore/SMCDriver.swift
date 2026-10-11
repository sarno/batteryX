import Foundation
import IOKit

public final class SMCDriver: @unchecked Sendable {
    public static let shared = SMCDriver()

    private var connection: io_connect_t = 0
    private let lock = NSLock()

    // SMC Commands
    private let KERNEL_INDEX_SMC: UInt32 = 2
    private let SMC_CMD_READ_KEYINFO: UInt8 = 9
    private let SMC_CMD_READ_BYTES: UInt8 = 5
    private let SMC_CMD_WRITE_BYTES: UInt8 = 6

    public struct SMCKeyData_vers {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    public struct SMCKeyData_pLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    public struct SMCKeyData_keyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    public struct SMCKeyData {
        var key: UInt32 = 0
        var vers = SMCKeyData_vers()
        var pLimitData = SMCKeyData_pLimitData()
        var keyInfo = SMCKeyData_keyInfo()
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        ) = (
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private init() {}

    public func open() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if connection != 0 { return true }

        let matching = IOServiceMatching("AppleSMC")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else {
            return false
        }
        defer { IOObjectRelease(service) }

        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        return result == kIOReturnSuccess && connection != 0
    }

    public func close() {
        lock.lock()
        defer { lock.unlock() }

        if connection != 0 {
            IOServiceClose(connection)
            connection = 0
        }
    }

    private func callSMC(input: inout SMCKeyData, output: inout SMCKeyData) -> kern_return_t {
        let inputSize = MemoryLayout<SMCKeyData>.stride
        var outputSize = MemoryLayout<SMCKeyData>.stride

        return IOConnectCallStructMethod(
            connection,
            KERNEL_INDEX_SMC,
            &input,
            inputSize,
            &output,
            &outputSize
        )
    }

    private func fourCharCode(from string: String) -> UInt32 {
        var code: UInt32 = 0
        for char in string.utf8.prefix(4) {
            code = (code << 8) + UInt32(char)
        }
        return code
    }

    /// Read 1-byte integer key (e.g., BCLM)
    public func readUint8(key: String) -> UInt8? {
        guard open() else { return nil }

        var input = SMCKeyData()
        var output = SMCKeyData()

        input.key = fourCharCode(from: key)
        input.data8 = SMC_CMD_READ_KEYINFO

        var kr = callSMC(input: &input, output: &output)
        guard kr == kIOReturnSuccess else { return nil }

        let size = output.keyInfo.dataSize
        input.keyInfo.dataSize = size
        input.data8 = SMC_CMD_READ_BYTES

        kr = callSMC(input: &input, output: &output)
        guard kr == kIOReturnSuccess else { return nil }

        return output.bytes.0
    }

    /// Write 1-byte integer key (e.g. BCLM with value 80)
    public func writeUint8(key: String, value: UInt8) -> Bool {
        guard open() else { return false }

        var input = SMCKeyData()
        var output = SMCKeyData()

        input.key = fourCharCode(from: key)
        input.data8 = SMC_CMD_READ_KEYINFO

        var kr = callSMC(input: &input, output: &output)
        guard kr == kIOReturnSuccess else { return false }

        input.keyInfo.dataSize = 1
        input.data8 = SMC_CMD_WRITE_BYTES
        input.bytes.0 = value

        kr = callSMC(input: &input, output: &output)
        return kr == kIOReturnSuccess
    }
}
