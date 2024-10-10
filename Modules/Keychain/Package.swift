// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Keychain",
            targets: ["Keychain"]
        ),
    ],
    targets: [
        .target(
            name: "Keychain"
        ),
        .testTarget(
            name: "KeychainTests",
            dependencies: ["Keychain"]
        ),
    ]
)
