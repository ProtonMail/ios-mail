// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxContacts",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxContacts", targets: ["InboxContacts"]),
    ],
    dependencies: [
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxDesignSystem"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../ProtonCore"),
        .package(path: "../ProtonTesting"),
        .package(path: "../ProtonSnapshotTesting")
    ],
    targets: [
        .target(
            name: "InboxContacts",
            dependencies: ["InboxCoreUI", "InboxDesignSystem", "proton_app_uniffi", "ProtonCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxContactsTests",
            dependencies: [
                .target(name: "InboxContacts"),
                .product(name: "ProtonTesting", package: "ProtonTesting"),
                .product(name: "ProtonSnapshotTesting", package: "ProtonSnapshotTesting")
            ]
        )
    ]
)
