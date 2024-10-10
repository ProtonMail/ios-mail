// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PContacts",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "PContacts",
            targets: ["PContacts"]
        ),
    ],
    dependencies: [.package(path: "DesignSystem")],
    targets: [
        .target(
            name: "PContacts",
            dependencies: ["DesignSystem"]
        ),
        .testTarget(
            name: "PContactsTests",
            dependencies: [
                .target(name: "PContacts"),
            ]
        ),
    ]
)
