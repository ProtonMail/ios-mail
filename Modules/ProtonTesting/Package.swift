// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonTesting",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonTesting", targets: ["ProtonTesting"])
    ],
    dependencies: [
        .package(path: "../ProtonCore")
    ],
    targets: [
        .target(name: "ProtonTesting", dependencies: ["ProtonCore"])
    ]
)
