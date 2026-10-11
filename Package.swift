// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BatteryX",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BatteryX",
            targets: ["BatteryX"]
        ),
        .executable(
            name: "batteryx-helper",
            targets: ["BatteryXHelper"]
        ),
        .library(
            name: "BatteryXCore",
            targets: ["BatteryXCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CSMCBridge",
            path: "Sources/CSMCBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "BatteryXCore",
            dependencies: ["CSMCBridge"],
            path: "Sources/BatteryXCore"
        ),
        .executableTarget(
            name: "BatteryX",
            dependencies: ["BatteryXCore"],
            path: "Sources/BatteryX"
        ),
        .executableTarget(
            name: "BatteryXHelper",
            dependencies: ["BatteryXCore"],
            path: "Sources/BatteryXHelper"
        ),
        .executableTarget(
            name: "BatteryXTestRunner",
            dependencies: ["BatteryXCore"],
            path: "Sources/BatteryXTestRunner"
        )
    ]
)
