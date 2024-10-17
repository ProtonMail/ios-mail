// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonCoreUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonCoreUI", targets: ["ProtonCoreUI"])
    ],
    dependencies: [],
    targets: [
        .target(name: "ProtonCoreUI"),
        .testTarget(name: "ProtonCoreUITests", dependencies: [.target(name: "ProtonCoreUI")])
    ]
)
