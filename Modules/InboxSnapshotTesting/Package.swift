// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxSnapshotTesting",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxSnapshotTesting", targets: ["InboxSnapshotTesting"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0")
    ],
    targets: [
        .target(
            name: "InboxSnapshotTesting",
            dependencies: [.product(name: "SnapshotTesting", package: "swift-snapshot-testing")]
        )
    ]
)
