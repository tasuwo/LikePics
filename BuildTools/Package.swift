// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "BuildTools",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.46.2"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.40.1"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
