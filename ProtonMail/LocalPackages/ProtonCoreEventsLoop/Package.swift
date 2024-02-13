// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonCoreEventsLoop",
    platforms: [.iOS(.v11), .macOS(.v11)],
    products: [
        .library(
            name: "ProtonCoreEventsLoop",
            targets: ["ProtonCoreEventsLoop"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/krzysztofzablocki/Difference.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "ProtonCoreEventsLoop",
            path: "Sources"
        ),
        .testTarget(
            name: "ProtonCoreEventsLoopTests",
            dependencies: ["Difference", "ProtonCoreEventsLoop"],
            path: "Tests"
        )
    ]
)
