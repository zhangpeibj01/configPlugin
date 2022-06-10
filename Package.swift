// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "configPlugin",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "tuist-config", targets: ["tuist-config"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/ProjectAutomation", .upToNextMajor(from: "3.4.0")), // Add ProjectAutomation as a package
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "tuist-config",
            dependencies: [
                .product(name: "ProjectAutomation", package: "ProjectAutomation"), // Integrate ProjectAutomation framework
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable")
            ]
        ),
    ]
)

