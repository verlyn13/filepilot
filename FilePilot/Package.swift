// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FilePilot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FilePilotCore",
            targets: ["FilePilotCore"]),
    ],
    dependencies: [
        // Quick Look support is built-in
        // Add libgit2 wrapper when needed
        // .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "0.7.0"),
    ],
    targets: [
        .target(
            name: "FilePilotCore",
            dependencies: [],
            path: "Sources/FilePilotCore"),
        .testTarget(
            name: "FilePilotCoreTests",
            dependencies: ["FilePilotCore"],
            path: "Tests/FilePilotCoreTests"),
    ]
)