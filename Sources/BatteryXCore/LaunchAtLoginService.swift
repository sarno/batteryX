import Foundation
import ServiceManagement

public final class LaunchAtLoginService: ObservableObject, @unchecked Sendable {
    public static let shared = LaunchAtLoginService()

    private let defaults = UserDefaults.standard
    private let launchAtLoginKey = "batteryx.isLaunchAtLoginEnabled"

    @Published public private(set) var isEnabled: Bool = false

    private var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.batteryx.app.plist")
    }

    private init() {
        self.isEnabled = checkCurrentStatus()
    }

    /// Checks whether launch at login is currently active (via SMAppService or fallback LaunchAgent)
    public func checkCurrentStatus() -> Bool {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled {
                return true
            }
        }
        return FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    /// Enable or disable launch at login
    @discardableResult
    public func setLaunchAtLogin(enabled: Bool) -> Bool {
        defaults.set(enabled, forKey: launchAtLoginKey)

        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                    _ = disableLaunchAgent() // Remove fallback if SMAppService succeeds
                    self.isEnabled = (SMAppService.mainApp.status == .enabled)
                    return true
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                    _ = disableLaunchAgent()
                    self.isEnabled = false
                    return true
                }
            } catch {
                print("[LaunchAtLoginService] SMAppService failed (\(error.localizedDescription)). Using LaunchAgent fallback...")
                let success = enabled ? enableLaunchAgent() : disableLaunchAgent()
                self.isEnabled = success ? enabled : false
                return success
            }
        } else {
            let success = enabled ? enableLaunchAgent() : disableLaunchAgent()
            self.isEnabled = success ? enabled : false
            return success
        }
    }

    /// Fallback LaunchAgent plist creator
    private func enableLaunchAgent() -> Bool {
        let plistURL = launchAgentURL
        let parentDir = plistURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

            let bundlePath = Bundle.main.bundleURL.path
            let execArgs: [String]
            if bundlePath.hasSuffix(".app") {
                execArgs = ["/usr/bin/open", "-a", bundlePath]
            } else if FileManager.default.fileExists(atPath: "/Applications/BatteryX.app") {
                execArgs = ["/usr/bin/open", "-a", "/Applications/BatteryX.app"]
            } else if let execPath = Bundle.main.executablePath {
                execArgs = [execPath]
            } else {
                execArgs = ["/usr/local/bin/BatteryX"]
            }

            let dict: [String: Any] = [
                "Label": "com.batteryx.app",
                "ProgramArguments": execArgs,
                "RunAtLoad": true,
                "ProcessType": "Interactive"
            ]

            let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
            try data.write(to: plistURL, options: .atomic)
            print("[LaunchAtLoginService] Successfully wrote LaunchAgent to \(plistURL.path)")
            return true
        } catch {
            print("[LaunchAtLoginService] Failed to write LaunchAgent: \(error)")
            return false
        }
    }

    /// Fallback LaunchAgent plist remover
    private func disableLaunchAgent() -> Bool {
        let plistURL = launchAgentURL
        if FileManager.default.fileExists(atPath: plistURL.path) {
            do {
                try FileManager.default.removeItem(at: plistURL)
                print("[LaunchAtLoginService] Successfully removed LaunchAgent at \(plistURL.path)")
                return true
            } catch {
                print("[LaunchAtLoginService] Failed to remove LaunchAgent: \(error)")
                return false
            }
        }
        return true
    }
}
