// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxCoreUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxCoreUI", targets: ["InboxCoreUI"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../InboxDesignSystem"),
        .package(path: "../InboxTesting"),
        .package(path: "../InboxSnapshotTesting"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.1.2"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0")
    ],
    targets: [
        .target(
            name: "InboxCoreUI",
            dependencies: [
                "InboxCore",
                "InboxDesignSystem",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Lottie", package: "lottie-spm")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxCoreUITests",
            dependencies: [
                .target(name: "InboxCoreUI"),
                .product(name: "InboxTesting", package: "InboxTesting"),
                .product(name: "InboxSnapshotTesting", package: "InboxSnapshotTesting"),
            ]
        )
    ]
)
