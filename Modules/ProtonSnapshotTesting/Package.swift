// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonSnapshotTesting",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonSnapshotTesting", targets: ["ProtonSnapshotTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "ProtonSnapshotTesting",
            dependencies: [.product(name: "SnapshotTesting", package: "swift-snapshot-testing")]
        )
    ]
)
