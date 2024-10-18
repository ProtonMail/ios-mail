// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonCore", targets: ["ProtonCore"])
    ],
    targets: [
        .target(name: "ProtonCore")
    ]
)
