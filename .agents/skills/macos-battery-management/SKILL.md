---
name: macos-battery-management
description: >-
  Expert guidelines and best practices for developing native macOS battery utilities in Swift 6, AppKit,
  IOKit (IOPowerSources, AppleSMC), SMC key manipulation (BCLM/CH0B), low-battery notification dispatching,
  and lightweight Menu Bar status items.
---

# macOS Battery Management & Swift Native Development Skill

This skill guides the design, implementation, and packaging of lightweight native macOS battery utilities (like BatteryX).

## 1. Battery State Monitoring (Event-Driven IOKit)
* Avoid aggressive polling timers (`Timer.scheduledTimer`). Instead, use event notifications provided by IOKit:
  ```swift
  import IOKit.ps

  let loopSource = IOPSNotificationCreateRunLoopSource({ context in
      // Battery percentage or power source changed
      BatteryMonitor.shared.updateStatus()
  }, nil).takeRetainedValue()

  CFRunLoopAddSource(CFRunLoopGetCurrent(), loopSource, .commonModes)
  ```
* Query battery details using `IOPSCopyPowerSourcesInfo()` and `IOPSCopyPowerSourcesList()`:
  - `kIOPSCurrentCapacityKey`: Current charge level.
  - `kIOPSMaxCapacityKey`: Maximum capacity.
  - `kIOPSIsChargingKey`: Boolean charging state.
  - `kIOPSPowerSourceStateKey`: Check if on battery (`kIOPSBatteryPowerValue`) or AC power (`kIOPSACPowerValue`).
  - `kIOPSTimeToEmptyKey`: Estimated minutes remaining.

## 2. Low-Battery Warning & Audio Alerting
* Use `UserNotifications` (`UNUserNotificationCenter`) to request and schedule notifications.
* For urgent alerts when battery is <= 20%:
  - Play an attention-grabbing system sound (`NSSound(named: "Sosumi")?.play()` or `AudioServicesPlaySystemSound(1005)`).
  - Present a persistent or high-priority modal/banner alert.

## 3. Charging Limit Mechanism (SMC Key Access)
* **SMC Connection**: Open connection to AppleSMC service via `IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))` and `IOServiceOpen`.
* **Intel Mac Battery Limit Key**:
  - `BCLM` (Battery Charge Limit Max, 1 byte uint8, e.g., `80` for 80%).
* **Apple Silicon Battery Control**:
  - `CH0B` / `CH0C` (Charging control keys) or leveraging macOS power assertion / SMJobBless helper daemon.
* **Privilege Separation**: Since writing to SMC requires `root` privileges:
  - Provide a tiny privileged CLI helper / daemon (`batteryx-helper`) installed in `/Library/PrivilegedHelperTools` or run via `sudo`.
  - The Menu Bar app communicates with the helper via XPC or Unix Domain Socket.

## 4. Menu Bar UI & Lifecycle
* Target macOS 13+ with lightweight `NSStatusItem` or SwiftUI `MenuBarExtra`.
* In `Info.plist`, set `LSUIElement` to `YES` to run as an accessory bar app without a Dock icon.
* Memory target: < 25MB RAM, CPU < 0.1% idle.
