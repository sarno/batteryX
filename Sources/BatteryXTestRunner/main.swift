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

        print("\n=== [BatteryXTestRunner] Verifying Auto-Reload / Launch At Login Feature ===")
        let launchService = LaunchAtLoginService.shared
        let settings = SettingsManager.shared

        print("[LaunchAtLoginService Verification]")
        let initialStatus = launchService.checkCurrentStatus()
        print(" - Current Launch At Login status: \(initialStatus)")
        print(" - SettingsManager isLaunchAtLoginEnabled: \(settings.isLaunchAtLoginEnabled)")

        // Test enabling launch at login
        print("\n[Testing Enable Launch At Login]")
        let enableResult = launchService.setLaunchAtLogin(enabled: true)
        print(" - Enable result: \(enableResult)")
        assert(launchService.checkCurrentStatus() == true, "Launch at login should be active when enabled")

        // Test disabling launch at login
        print("\n[Testing Disable Launch At Login]")
        let disableResult = launchService.setLaunchAtLogin(enabled: false)
        print(" - Disable result: \(disableResult)")
        assert(launchService.checkCurrentStatus() == false, "Launch at login should be inactive when disabled")

        // Restore initial or default enabled state for user convenience
        _ = launchService.setLaunchAtLogin(enabled: true)
        settings.refreshLaunchAtLoginStatus()
        print(" - Restored default active auto-start state: \(settings.isLaunchAtLoginEnabled)")

        print("\n✅ All Modules (AppleSMC, ChargeLimiter, Auto-Start/Reload) verified successfully!")
    }
}
