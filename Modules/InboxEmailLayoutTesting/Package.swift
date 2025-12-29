// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxEmailLayoutTesting",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxEmailLayoutTesting", targets: ["InboxEmailLayoutTesting"])
    ],
    targets: [
        .target(
            name: "InboxEmailLayoutTesting"
        ),
        .testTarget(
            name: "InboxEmailLayoutTestingTests",
            dependencies: ["InboxEmailLayoutTesting"]
        ),
    ]
)
