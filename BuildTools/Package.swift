// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "BuildTools",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.44.16"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.39.2"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
