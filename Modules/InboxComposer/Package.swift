// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxComposer",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxComposer", targets: ["InboxComposer"]),
    ],
    dependencies: [
        .package(path: "../InboxContacts"),
        .package(path: "../InboxCore"),
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxDesignSystem"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi")
    ],
    targets: [
        .target(
            name: "InboxComposer",
            dependencies: ["InboxContacts", "InboxCore", "InboxCoreUI", "InboxDesignSystem", "proton_app_uniffi"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxComposerTests",
            dependencies: [
                .target(name: "InboxComposer"),
                .product(name: "InboxTesting", package: "InboxTesting")
            ]
        )
    ]
)
