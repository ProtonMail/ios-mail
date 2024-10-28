// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxTesting",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxTesting", targets: ["InboxTesting"])
    ],
    dependencies: [
        .package(path: "../InboxCore")
    ],
    targets: [
        .target(name: "InboxTesting", dependencies: ["InboxCore"])
    ]
)
