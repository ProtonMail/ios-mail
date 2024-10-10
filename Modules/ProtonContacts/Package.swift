// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProtonContacts",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProtonContacts", targets: ["ProtonContacts"]),
    ],
    dependencies: [
        .package(path: "DesignSystem")
    ],
    targets: [
        .target(name: "ProtonContacts", dependencies: ["DesignSystem"]),
        .testTarget(
            name: "ProtonContactsTests",
            dependencies: [.target(name: "ProtonContacts")]
        ),
    ]
)
