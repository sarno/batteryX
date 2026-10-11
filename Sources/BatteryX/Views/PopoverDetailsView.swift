import SwiftUI
import BatteryXCore

public struct PopoverDetailsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var isHelperInstalled = HelperInstallerService.shared.isHelperInstalledAndValid
    @State private var isInstallingHelper = false

    let batteryInfo: BatteryInfo
    let onTopUpOnce: () -> Void
    let onQuit: () -> Void

    public init(
        batteryInfo: BatteryInfo,
        onTopUpOnce: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.batteryInfo = batteryInfo
        self.onTopUpOnce = onTopUpOnce
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Battery Status
            HStack(spacing: 12) {
                Image(systemName: batteryIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 24)
                    .foregroundColor(batteryColor)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("\(batteryInfo.currentPercentage)%")
                            .font(.system(size: 20, weight: .bold))
                        if batteryInfo.isCharging {
                            Text("(Charging)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else if batteryInfo.isPluggedIn {
                            Text("(AC Power)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let time = batteryInfo.timeRemainingMinutes {
                        Text("\(time / 60)j \(time % 60)m tersisa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if batteryInfo.isCharging {
                        Text("Daya 96W terhubung")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Menghitung perkiraan waktu...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 4)

            // Helper Permission Warning Banner (If not yet installed)
            if !isHelperInstalled {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Izin Pembatas Baterai Diperlukan")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("Klik untuk mengaktifkan kontrol hardware SMC.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(isInstallingHelper ? "Memasang..." : "Aktifkan") {
                        isInstallingHelper = true
                        HelperInstallerService.shared.promptAndInstallHelperIfNeeded { success in
                            Task { @MainActor in
                                isInstallingHelper = false
                                isHelperInstalled = success
                                if success {
                                    settings.syncChargeLimiter()
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .disabled(isInstallingHelper)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.12))
                .cornerRadius(8)
            }

            Divider()

            // Section 1: Under-charge Warning (Early Warning System)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Peringatan Baterai Lemah", systemImage: "bell.badge.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(settings.warningThreshold)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                Text("Bunyikan alarm sebelum daya drop ke level kritis 1%.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(settings.warningThreshold) },
                        set: { settings.warningThreshold = Int($0) }
                    ),
                    in: 10...35,
                    step: 5
                )

                Toggle("Aktifkan Bunyi Alarm (Audio Alert)", isOn: $settings.isSoundAlertEnabled)
                    .font(.caption)
            }

            Divider()

            // Section 2: Charge Limiter (Over-charge Protection)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Batas Pengisian Daya", systemImage: "bolt.shield.fill")
                        .font(.headline)
                    Spacer()
                    Text(settings.isChargeLimiterEnabled ? "\(settings.chargeLimit)%" : "Mati")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(settings.isChargeLimiterEnabled ? .blue : .secondary)
                }

                Text("Hentikan pengisian saat mencapai batas agar sel baterai awet.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Toggle("Batasi Pengisian Daya", isOn: $settings.isChargeLimiterEnabled)
                    .font(.caption)

                if settings.isChargeLimiterEnabled {
                    Slider(
                        value: Binding(
                            get: { Double(settings.chargeLimit) },
                            set: { settings.chargeLimit = Int($0) }
                        ),
                        in: 50...90,
                        step: 5
                    )
                }
            }

            Divider()

            // Section 3: Auto-Start on macOS Restart / Login
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Mulai Otomatis (Auto-Start)", systemImage: "arrow.clockwise.circle.fill")
                        .font(.headline)
                    Spacer()
                    Text(settings.isLaunchAtLoginEnabled ? "Aktif" : "Mati")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(settings.isLaunchAtLoginEnabled ? .green : .secondary)
                }

                Text("Otomatis aktifkan BatteryX dan proteksi baterai saat Mac dinyalakan atau restart.")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Toggle("Buka otomatis saat Mac Restart / Login", isOn: $settings.isLaunchAtLoginEnabled)
                    .font(.caption)
            }

            Divider()

            // Actions & Footer
            HStack {
                Button(action: onTopUpOnce) {
                    Label("Charge ke 100% Sekali", systemImage: "bolt.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Keluar", action: onQuit)
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            isHelperInstalled = HelperInstallerService.shared.isHelperInstalledAndValid
            settings.refreshLaunchAtLoginStatus()
        }
    }

    private var batteryIconName: String {
        if batteryInfo.isCharging {
            return "battery.100.bolt"
        }
        let level = batteryInfo.currentPercentage
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }

    private var batteryColor: Color {
        if batteryInfo.isCharging { return .green }
        let level = batteryInfo.currentPercentage
        if level <= settings.urgentThreshold { return .red }
        if level <= settings.warningThreshold { return .orange }
        return .primary
    }
}
