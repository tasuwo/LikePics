// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LikePicsKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v15), .macOS(.v14)
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AppDesktopFeature", targets: ["AppDesktopFeature"]),
        .library(name: "AlbumMultiSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "AlbumSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "TagSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "ShareExtensionMobileFeature", targets: ["ShareExtensionMobileFeature"]),
        .library(name: "ShareExtensionDesktopFeature", targets: ["ShareExtensionDesktopFeature"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "MobileTransition", targets: ["MobileTransition"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "ClipCreationFeature", targets: ["ClipCreationFeature"]),
        .library(name: "ClipCreationDesktopFeature", targets: ["ClipCreationDesktopFeature"]),
        .library(name: "ClipPreviewPlayConfigurationModalFeature", targets: ["ClipPreviewPlayConfigurationModalFeature"]),
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
        .package(url: "https://github.com/tasuwo/PersistentStack", .upToNextMajor(from: "0.8.1")),
        .package(url: "https://github.com/tasuwo/swift", .upToNextMajor(from: "0.8.1")),
        .package(url: "https://github.com/tasuwo/MasonryGrid", .upToNextMajor(from: "0.0.1-alpha.5")),
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMajor(from: "1.0.0"))
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
                "MobileTransition",
                .product(name: "PersistentStack", package: "PersistentStack")
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "AppDesktopFeature",
            dependencies: [
                "Domain",
                "Persistence",
                .product(name: "MasonryGrid", package: "MasonryGrid"),
                .product(name: "PersistentStack", package: "PersistentStack")
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "ShareExtensionMobileFeature",
            dependencies: [
                "Common",
                "Domain",
                "AlbumMultiSelectionModalFeature",
                "ClipCreationFeature",
                "TagSelectionModalFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie"
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "ShareExtensionDesktopFeature",
            dependencies: [
                "Persistence",
                "Smoothie",
                .product(name: "PersistentStack", package: "PersistentStack")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "ClipCreationDesktopFeature",
            dependencies: [
                "Persistence",
                "Smoothie",
                .product(name: "MasonryGrid", package: "MasonryGrid")
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),

        // MARK: - Core

        .target(
            name: "Domain",
            dependencies: [
                "Common",
                "Smoothie"
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
                "Smoothie",
                "MobileTransition"
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "MobileTransition",
            dependencies: [],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
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
                "CompositeKit",
                "MobileTransition"
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),

        // MARK: - Helper

        .target(
            name: "CompositeKit",
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "Smoothie",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
        .target(
            name: "Common",
            plugins: [
                .plugin(name: "LintSwift", package: "swift")
            ]
        ),
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
