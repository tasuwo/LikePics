// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LikePicsKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AlbumMultiSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "AlbumSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
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
        .package(url: "https://github.com/realm/realm-cocoa", .upToNextMinor(from: "10.44.0")),
        .package(url: "https://github.com/phimage/Erik", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/tasuwo/PersistentStack", .upToNextMinor(from: "0.6.0"))
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
                "AlbumMultiSelectionModalFeature",
                "AlbumSelectionModalFeature",
                "TagSelectionModalFeature",
                "ClipCreationFeature",
                "ClipPreviewPlayConfigurationModalFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie",
                .product(name: "PersistentStack", package: "PersistentStack")
            ]
        ),
        .target(
            name: "ShareExtensionFeature",
            dependencies: [
                "Common",
                "Domain",
                "AlbumMultiSelectionModalFeature",
                "ClipCreationFeature",
                "TagSelectionModalFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie"
            ]
        ),

        // MARK: - Feature

        .target(
            name: "AlbumMultiSelectionModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit"
            ]
        ),
        .target(
            name: "AlbumSelectionModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit"
            ]
        ),
        .target(
            name: "TagSelectionModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit"
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
        .target(
            name: "ClipPreviewPlayConfigurationModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit"
            ]
        ),

        // MARK: - Core

        .target(
            name: "Domain",
            dependencies: [
                "Common",
                "Smoothie"
            ]
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
                .product(name: "Realm", package: "realm-cocoa"),
                .product(name: "RealmSwift", package: "realm-cocoa")
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
