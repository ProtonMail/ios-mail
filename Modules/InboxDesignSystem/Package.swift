// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxDesignSystem",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxDesignSystem", targets: ["InboxDesignSystem"])
    ],
    targets: [
        .target(name: "InboxDesignSystem", resources: [.process("Resources")])
    ]
)
