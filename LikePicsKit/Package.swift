// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "LikePicsKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "TagSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "ShareExtensionFeature", targets: ["ShareExtensionFeature"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "ClipCreationFeature", targets: ["ClipCreationFeature"]),
        .library(name: "LikePicsUIKit", targets: ["LikePicsUIKit"]),
        .library(name: "CompositeKit", targets: ["CompositeKit"]),
        .library(name: "Smoothie", targets: ["Smoothie"]),
        .library(name: "Common", targets: ["Common"]),
        .library(name: "Environment", targets: ["Environment"]),
        .library(name: "TestHelper", targets: ["TestHelper"])
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa", .upToNextMinor(from: "10.28.0")),
        .package(name: "Erik", url: "https://github.com/phimage/Erik", .exact("5.1.0"))
    ],
    targets: [
        // MARK: - App

        .target(
            name: "AppFeature",
            dependencies: [
                "Common",
                "CompositeKit",
                "Domain",
                "Environment",
                "TagSelectionModalFeature",
                "ClipCreationFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie"
            ]
        ),
        .target(
            name: "ShareExtensionFeature",
            dependencies: [
                "Common",
                "Domain",
                "ClipCreationFeature",
                "Persistence",
                "Smoothie"
            ]
        ),

        // MARK: - Feature

        .target(
            name: "TagSelectionModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit",
            ]
        ),
        .target(
            name: "ClipCreationFeature",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit",
                .product(name: "Erik", package: "Erik")
            ]
        ),

        // MARK: - Core

        .target(
            name: "Domain",
            dependencies: ["Common"]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                "TestHelper"
            ]
        ),
        .target(
            name: "Environment",
            dependencies: [
                "Common",
                "Domain",
                "Smoothie"
            ]
        ),

        // MARK: - Persistence

        .target(
            name: "Persistence",
            dependencies: [
                "Common",
                "Domain",
                .product(name: "Realm", package: "Realm"),
                .product(name: "RealmSwift", package: "Realm")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                "TestHelper"
            ],
            resources: [
                .process("Resources/")
            ]
        ),

        // MARK: - UI

        .target(
            name: "LikePicsUIKit",
            dependencies: [
                "Smoothie",
                "Domain",
                "Common",
                "CompositeKit"
            ]
        ),

        // MARK: - Helper

        .target(name: "CompositeKit"),
        .target(name: "Smoothie"),
        .target(name: "Common"),
        .target(
            name: "TestHelper",
            dependencies: [
                "Common",
                "Domain",
                "Environment",
                "Persistence",
                "Smoothie",
                "ClipCreationFeature",
                "LikePicsUIKit"
            ]
        )
    ]
)
