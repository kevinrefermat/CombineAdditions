// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineAdditions",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "CombineAdditions",
            targets: ["CombineAdditions"]
        ),
    ],
    targets: [
        .target(
            name: "CombineAdditions",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "CombineAdditionsTests",
            dependencies: ["CombineAdditions"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
