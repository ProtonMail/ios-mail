// swift-tools-version: 5.9
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
    ],
    targets: [
        .target(name: "TestableShareExtension", dependencies: ["InboxComposer", "InboxKeychain"]),
        .testTarget(name: "TestableShareExtensionTests", dependencies: ["InboxSnapshotTesting", "TestableShareExtension"]),
    ]
)
