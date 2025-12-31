// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxEmailLayoutTesting",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxEmailLayoutTesting", targets: ["InboxEmailLayoutTesting"])
    ],
    dependencies: [
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "InboxEmailLayoutTesting",
            dependencies: ["proton_app_uniffi"],
        ),
        .testTarget(
            name: "InboxEmailLayoutTestingTests",
            dependencies: [
                .target(name: "InboxEmailLayoutTesting"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            resources: [
                .process("TestAssets")
            ]
        ),
    ]
)
