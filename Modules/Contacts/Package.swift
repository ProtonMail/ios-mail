// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Contacts",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Contacts",
            targets: ["Contacts"]
        ),
    ],
    targets: [
        .target(
            name: "Contacts"
        ),
        .testTarget(
            name: "ContactsTests",
            dependencies: ["Contacts"]
        ),
    ]
)
