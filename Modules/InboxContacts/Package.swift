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
        .package(path: "../InboxCore"),
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxDesignSystem"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../ProtonSnapshotTesting")
    ],
    targets: [
        .target(
            name: "InboxContacts",
            dependencies: ["InboxCore", "InboxCoreUI", "InboxDesignSystem", "proton_app_uniffi"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxContactsTests",
            dependencies: [
                .target(name: "InboxContacts"),
                .product(name: "InboxTesting", package: "InboxTesting"),
                .product(name: "ProtonSnapshotTesting", package: "ProtonSnapshotTesting")
            ]
        )
    ]
)
