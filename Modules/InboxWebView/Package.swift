// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxWebView",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxWebView", targets: ["InboxWebView"])
    ],
    dependencies: [
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    ],
    targets: [
        .target(
            name: "InboxWebView",
            dependencies: ["proton_app_uniffi"],
        ),
        .testTarget(
            name: "InboxWebViewTests",
            dependencies: [
                .target(name: "InboxWebView"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            resources: [
                .process("TestAssets")
            ]
        ),
    ]
)
