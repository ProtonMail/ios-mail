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
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxSnapshotTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../../ProtonPackages/et-protoncore/platform/apple/Payments/PaymentsNG"),
        .package(path: "../../ProtonPackages/et-protoncore/platform/apple/ProtonCoreET"),
    ],
    targets: [
        .target(
            name: "InboxIAP",
            dependencies: [
                "InboxCoreUI",
                "PaymentsNG",
                "proton_app_uniffi",
                .product(name: "UIFoundations", package: "ProtonCoreET"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxIAPTests",
            dependencies: [
                .target(name: "InboxIAP"),
                .product(name: "InboxSnapshotTesting", package: "InboxSnapshotTesting"),
            ]
        ),
    ]
)
