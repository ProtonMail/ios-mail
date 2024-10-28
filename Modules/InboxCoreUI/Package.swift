// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxCoreUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxCoreUI", targets: ["InboxCoreUI"])
    ],
    dependencies: [],
    targets: [
        .target(name: "InboxCoreUI"),
        .testTarget(name: "InboxCoreUITests", dependencies: [.target(name: "InboxCoreUI")])
    ]
)
