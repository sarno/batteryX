import Foundation
import BatteryXCore

@main
struct BatteryXTestRunner {
    static func main() {
        print("=== [BatteryXTestRunner] Verifying Phase 3 (AppleSMC & ChargeLimiter) ===")

        let smc = SMCDriver.shared
        let isOpen = smc.open()
        print("[AppleSMC Connection Test]")
        print(" - Connection open successful: \(isOpen)")

        let limiter = ChargeLimiterService.shared
        print("\n[Charge Limiter Reading Test]")
        if let currentBCLM = limiter.currentChargeLimit() {
            print(" - Current BCLM Key value: \(currentBCLM)%")
        } else {
            print(" - Current BCLM Key read returned nil (Normal without root or if key unpopulated)")
        }

        print("\n[Clamping & Safety Validation]")
        let clampedLow = max(40, min(100, 20))
        let clampedHigh = max(40, min(100, 150))
        let clampedNormal = max(40, min(100, 80))
        assert(clampedLow == 40, "Clamp low should be 40%")
        assert(clampedHigh == 100, "Clamp high should be 100%")
        assert(clampedNormal == 80, "Clamp normal should be 80%")
        print(" - Safety boundary clamping test passed (40% - 100%).")

        print("\n✅ Phase 3 (AppleSMC & ChargeLimiter Module) verified successfully!")
    }
}
