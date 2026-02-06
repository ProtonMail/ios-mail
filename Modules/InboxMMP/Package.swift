// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxMMP",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxMMP", targets: ["InboxMMP"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
    ],
    targets: [
        .target(
            name: "InboxMMP",
            dependencies: [
                "InboxCore",
                "proton_app_uniffi",
            ]
        ),
        .testTarget(
            name: "InboxMMPTests",
            dependencies: [
                .target(name: "InboxMMP"),
                .product(name: "InboxTesting", package: "InboxTesting"),
            ]
        ),
    ]
)
