import AppKit
import SwiftUI
import BatteryXCore

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var monitor = BatteryMonitor.shared
    private var alertEngine = AlertEngine.shared
    private var settings = SettingsManager.shared

    private var currentBatteryInfo: BatteryInfo = BatteryInfo()

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        startMonitoring()
        NotificationService.shared.requestAuthorization()

        // Restore and sync settings on launch (e.g. after macOS reboot / restart)
        restoreAndSyncSettings()

        // Auto-check and prompt for helper install on initial launch if not yet installed
        checkAndPromptHelperInstall()
    }

    private func restoreAndSyncSettings() {
        // Reapply hardware charge limiter (re-programs SMC BCLM after reboot)
        settings.syncChargeLimiter()

        // Sync alert engine config
        settings.syncAlertEngine()

        // Refresh launch-at-login state
        settings.refreshLaunchAtLoginStatus()
    }

    private func checkAndPromptHelperInstall() {
        if !HelperInstallerService.shared.isHelperInstalledAndValid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                HelperInstallerService.shared.promptAndInstallHelperIfNeeded { [weak self] success in
                    Task { @MainActor [weak self] in
                        if success {
                            self?.settings.syncChargeLimiter()
                        }
                    }
                }
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(togglePopover)
            updateButtonTitle(info: currentBatteryInfo)
        }
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 530)
        popover.behavior = .transient
        self.popover = popover
        updatePopoverContent()
    }

    private func updatePopoverContent() {
        let view = PopoverDetailsView(
            batteryInfo: currentBatteryInfo,
            onTopUpOnce: { [weak self] in
                self?.topUpOnce()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )
        popover?.contentViewController = NSHostingController(rootView: view)
    }

    private func startMonitoring() {
        monitor.startMonitoring { [weak self] info in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentBatteryInfo = info
                self.updateButtonTitle(info: info)
                self.updatePopoverContent()
                self.alertEngine.evaluate(battery: info)
            }
        }
    }

    private func updateButtonTitle(info: BatteryInfo) {
        guard let button = statusItem?.button else { return }

        let iconName: String
        if info.isCharging {
            iconName = "bolt.fill"
        } else if info.currentPercentage <= settings.urgentThreshold {
            iconName = "exclamationmark.triangle.fill"
        } else {
            iconName = "battery.100"
        }

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "BatteryX")?
            .withSymbolConfiguration(symbolConfig)

        button.image = image
        button.imagePosition = .imageLeading

        if let time = info.timeRemainingMinutes, !info.isPluggedIn {
            button.title = "\(info.currentPercentage)% (\(time / 60):\(String(format: "%02d", time % 60)))"
        } else {
            button.title = "\(info.currentPercentage)%"
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            updatePopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func topUpOnce() {
        _ = ChargeLimiterService.shared.resetChargeLimit()
        NotificationService.shared.postNotification(
            title: "⚡️ BatteryX: Top Up Aktif",
            body: "Pengisian daya diizinkan sampai 100% untuk sesi ini."
        )
    }
}

@main
struct BatteryXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as NSStatusItem accessory application
        controller = MenuBarController()
    }
}
