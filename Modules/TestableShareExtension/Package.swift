// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestableShareExtension",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TestableShareExtension", targets: ["TestableShareExtension"])
    ],
    dependencies: [
        .package(path: "../InboxComposer"),
        .package(path: "../InboxKeychain"),
        .package(path: "../InboxSnapshotTesting"),
        .package(path: "../InboxTesting"),
        .package(url: "https://gitlab.protontech.ch/apple/shared/ProtonUIFoundations.git", exact: "1.3.2"),
    ],
    targets: [
        .target(
            name: "TestableShareExtension",
            dependencies: [
                "InboxComposer",
                "InboxKeychain",
                .product(name: "ProtonUIFoundations", package: "ProtonUIFoundations"),
            ]
        ),
        .testTarget(
            name: "ShareExtensionTests",
            dependencies: ["InboxSnapshotTesting", "InboxTesting", "TestableShareExtension"]
        ),
    ]
)
