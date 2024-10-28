// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxCore", targets: ["InboxCore"])
    ],
    targets: [
        .target(name: "InboxCore")
    ]
)
