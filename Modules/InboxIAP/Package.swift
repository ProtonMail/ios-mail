// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxIAP",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxIAP", targets: ["InboxIAP"])
    ],
    dependencies: [
        .package(path: "../InboxAttribution"),
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxSnapshotTesting"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../../ProtonPackages/et-protoncore/platform/apple/Payments/PaymentsNG"),
    ],
    targets: [
        .target(
            name: "InboxIAP",
            dependencies: [
                "InboxAttribution",
                "InboxCoreUI",
                "PaymentsNG",
                "proton_app_uniffi",
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxIAPTests",
            dependencies: [
                .target(name: "InboxIAP"),
                .product(name: "InboxTesting", package: "InboxTesting"),
                .product(name: "InboxSnapshotTesting", package: "InboxSnapshotTesting"),
            ]
        ),
    ]
)
