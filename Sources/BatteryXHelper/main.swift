import Foundation
import BatteryXCore
import Darwin

// Ensure effective user id 0 is converted to real uid 0 for macOS IOKit authorization
setuid(0)

let args = CommandLine.arguments

guard args.count >= 2 else {
    print("""
    BatteryX Privileged Helper v1.0.0
    Usage:
      batteryx-helper get-limit
      batteryx-helper set-limit <percentage 40-100>
      batteryx-helper reset
    """)
    exit(1)
}

let command = args[1].lowercased()
let service = ChargeLimiterService.shared

switch command {
case "get-limit":
    if let limit = service.currentChargeLimit() {
        print("CURRENT_LIMIT=\(limit)")
        exit(0)
    } else {
        print("ERROR: Failed to read charge limit (Requires AppleSMC support or root permission)")
        exit(2)
    }

case "set-limit":
    guard args.count >= 3, let val = Int(args[2]) else {
        print("ERROR: Missing percentage (e.g. set-limit 80)")
        exit(1)
    }
    let success = service.setChargeLimit(percentage: val)
    if success {
        print("SUCCESS: Charge limit set to \(max(40, min(100, val)))%")
        exit(0)
    } else {
        print("ERROR: Failed to write SMC key BCLM. Ensure running as root (sudo).")
        exit(2)
    }

case "reset":
    let success = service.resetChargeLimit()
    if success {
        print("SUCCESS: Reset to standard 100% charging")
        exit(0)
    } else {
        print("ERROR: Failed to reset charge limit. Ensure running as root (sudo).")
        exit(2)
    }

default:
    print("ERROR: Unknown command '\(command)'")
    exit(1)
}
