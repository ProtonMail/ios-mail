// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxAttribution",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxAttribution", targets: ["InboxAttribution"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
    ],
    targets: [
        .target(
            name: "InboxAttribution",
            dependencies: [
                "InboxCore",
                "proton_app_uniffi",
            ]
        ),
        .testTarget(
            name: "InboxAttributionTests",
            dependencies: [
                .target(name: "InboxAttribution"),
                .product(name: "InboxTesting", package: "InboxTesting"),
            ]
        ),
    ]
)
