// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonContacts",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonContacts", targets: ["ProtonContacts"]),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../ProtonCore"),
        .package(path: "../ProtonCoreUI"),
        .package(path: "../ProtonTesting"),
        .package(path: "../ProtonSnapshotTesting")
    ],
    targets: [
        .target(
            name: "ProtonContacts",
            dependencies: ["DesignSystem", "proton_app_uniffi", "ProtonCore", "ProtonCoreUI"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ProtonContactsTests",
            dependencies: [
                .target(name: "ProtonContacts"),
                .product(name: "ProtonTesting", package: "ProtonTesting"),
                .product(name: "ProtonSnapshotTesting", package: "ProtonSnapshotTesting")
            ]
        ),
    ]
)
