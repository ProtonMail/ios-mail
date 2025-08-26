// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxKeychain",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxKeychain", targets: ["InboxKeychain"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
    ],
    targets: [
        .target(name: "InboxKeychain", dependencies: ["InboxCore", "proton_app_uniffi"]),
        .testTarget(name: "InboxKeychainTests", dependencies: ["InboxKeychain"]),
    ]
)
