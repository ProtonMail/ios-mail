// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonCoreICS",
    platforms: [.iOS(.v11), .macOS(.v11)],
    products: [
        .library(
            name: "ProtonCoreICS",
            targets: ["ProtonCoreICS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .target(
            name: "ProtonCoreICS",
            dependencies: []
        ),
        .testTarget(
            name: "ProtonCoreICSTests",
            dependencies: ["ProtonCoreICS", "Quick", "Nimble"]
        ),
    ]
)
