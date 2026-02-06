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
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.8.0"),
    ],
    targets: [
        .target(
            name: "InboxCore",
            dependencies: [
                "proton_app_uniffi",
                "TryCatch",
                .product(name: "Sentry", package: "sentry-cocoa"),
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
