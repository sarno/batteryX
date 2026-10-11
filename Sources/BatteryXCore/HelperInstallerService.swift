import Foundation
import AppKit

public final class HelperInstallerService: @unchecked Sendable {
    public static let shared = HelperInstallerService()

    public let targetPath = "/usr/local/bin/batteryx-helper"

    private init() {}

    /// Checks if batteryx-helper is installed with root SUID permissions
    public var isHelperInstalledAndValid: Bool {
        guard FileManager.default.fileExists(atPath: targetPath) else { return false }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: targetPath),
              let posixPermissions = attributes[.posixPermissions] as? NSNumber,
              let ownerAccountID = attributes[.ownerAccountID] as? NSNumber else {
            return false
        }
        // Must be owned by root (uid 0) and have SUID or execute permissions
        let isRoot = (ownerAccountID.intValue == 0)
        let isExecutable = (posixPermissions.intValue & 0o111 != 0)
        return isRoot && isExecutable
    }

    /// Prompt user with macOS native administrator authorization modal and install helper
    public func promptAndInstallHelperIfNeeded(completion: (@Sendable (Bool) -> Void)? = nil) {
        if isHelperInstalledAndValid {
            completion?(true)
            return
        }

        // Locate bundled helper
        guard let helperSource = Bundle.main.path(forResource: "batteryx-helper", ofType: nil) ??
              Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/batteryx-helper").path as String? else {
            completion?(false)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            mkdir -p /usr/local/bin
            cp "\(helperSource)" "\(self.targetPath)"
            chown root:wheel "\(self.targetPath)"
            chmod 4755 "\(self.targetPath)"
            """

            let escapedScript = script.replacingOccurrences(of: "\"", with: "\\\"")
            let appleScript = "do shell script \"\(escapedScript)\" with prompt \"BatteryX memerlukan izin satu kali untuk memasang helper pembatas pengisian daya (AppleSMC):\" with administrator privileges"

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript]

            do {
                try process.run()
                process.waitUntilExit()
                let success = (process.terminationStatus == 0) && self.isHelperInstalledAndValid
                DispatchQueue.main.async {
                    completion?(success)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
}
