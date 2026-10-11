# BatteryX Engineering & Safety Standards

## 1. Battery Safety & SMC Control
* **Fail-Safe Charging**: Always ensure charging can default to normal charging if the daemon/app exits unexpectedly.
* **SMC Operations**:
  - Intel Macs: Utilize key `BCLM` (Battery Charge Level Max) or `CH0B`/`CH0C` where applicable via AppleSMC.
  - Apple Silicon Macs: Utilize SMC power keys / `CH0B` control or Apple Silicon charging inhibit mechanisms.
* **Safe Boundaries**: Clamp user-configured charging limits strictly between 40% and 90% (recommended default: 80%).

## 2. Low Battery Warnings & Aggressive Alerting
* **Custom Low Threshold**: Default warning at 20% (configurable between 10% and 35%).
* **Notification Levels**:
  - *Warning Level (e.g. 20%)*: Post standard macOS banner notification with system chime.
  - *Critical Level (e.g. 10%)*: Post critical/urgent alert sound and repetitive reminder every 60 seconds until charger is plugged in.
* **Auto Low Power Mode**: Optionally trigger Low Power Mode (`pmset -a lowpowermode 1`) automatically when battery hits threshold.

## 3. Performance & Memory Footprint
* The daemon / Menu Bar app MUST idle at < 0.1% CPU and consume < 25MB RAM.
* Battery status queries via `IOPowerSources` and `IOPSNotificationCreateRunLoopSource` must be event-driven rather than high-frequency polling.
