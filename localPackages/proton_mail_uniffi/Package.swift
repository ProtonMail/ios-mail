// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "proton_mail_uniffi",
    platforms: [
      .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "proton_mail_uniffi",
            targets: ["proton_mail_uniffi", "proton_mail_uniffi_ffi"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "proton_mail_uniffi",
            dependencies: ["proton_mail_uniffi_ffi"]
        ),
         .binaryTarget(name: "proton_mail_uniffi_ffi", path: "Sources/proton_mail_uniffi_ffi.xcframework"),
    ]
)

