// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InboxCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "InboxCore", targets: ["InboxCore"])
    ],
    dependencies: [
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
        .package(path: "../TryCatch"),
    ],
    targets: [
        .target(
            name: "InboxCore",
            dependencies: ["proton_app_uniffi", "TryCatch"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
