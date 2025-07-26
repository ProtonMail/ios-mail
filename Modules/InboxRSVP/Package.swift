// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxRSVP",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxRSVP", targets: ["InboxRSVP"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../InboxCoreUI"),
        .package(path: "../InboxDesignSystem"),
        .package(path: "../InboxSnapshotTesting"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../../ProtonPackages/et-protoncore/platform/apple/ProtonCoreET"),
    ],
    targets: [
        .target(
            name: "InboxRSVP",
            dependencies: [
                "InboxCore",
                "InboxCoreUI",
                "InboxDesignSystem",
                "proton_app_uniffi",
                .product(name: "AccountLogin", package: "ProtonCoreET"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "InboxRSVPTests",
            dependencies: [
                .target(name: "InboxRSVP"),
                .product(name: "InboxSnapshotTesting", package: "InboxSnapshotTesting"),
                .product(name: "InboxTesting", package: "InboxTesting"),
            ]
        ),
    ]
)
