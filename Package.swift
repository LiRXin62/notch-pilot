// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchPilot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NotchPilot",
            targets: ["NotchPilot"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NotchPilot",
            path: "Sources/NotchPilot"
        )
    ]
)

