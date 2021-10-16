// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LikePicsKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(
            name: "ForestKit",
            targets: ["ForestKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ForestKit",
            dependencies: []
        ),
    ]
)
