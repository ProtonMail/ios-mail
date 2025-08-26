// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestableNotificationService",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TestableNotificationService", targets: ["TestableNotificationService"])
    ],
    dependencies: [
        .package(path: "../InboxCore"),
        .package(path: "../InboxKeychain"),
        .package(path: "../../ProtonPackages/proton_app_uniffi"),
    ],
    targets: [
        .target(name: "TestableNotificationService", dependencies: ["InboxCore", "InboxKeychain", "proton_app_uniffi"]),
        .testTarget(name: "NotificationServiceTests", dependencies: ["TestableNotificationService"]),
    ]
)
