// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LikePicsKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v15), .macOS("15"),
    ],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "AppDesktopFeature", targets: ["AppDesktopFeature"]),
        .library(name: "AlbumMultiSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "AlbumSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "TagSelectionModalFeature", targets: ["TagSelectionModalFeature"]),
        .library(name: "ShareExtensionMobileFeature", targets: ["ShareExtensionMobileFeature"]),
        .library(name: "ShareExtensionDesktopFeature", targets: ["ShareExtensionDesktopFeature"]),
        .library(name: "ShareExtensionFeatureCore", targets: ["ShareExtensionFeatureCore"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "MobileTransition", targets: ["MobileTransition"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "ClipCreationFeature", targets: ["ClipCreationFeature"]),
        .library(name: "ClipCreationDesktopFeature", targets: ["ClipCreationDesktopFeature"]),
        .library(name: "ClipCreationFeatureCore", targets: ["ClipCreationFeatureCore"]),
        .library(name: "ClipPreviewPlayConfigurationModalFeature", targets: ["ClipPreviewPlayConfigurationModalFeature"]),
        .library(name: "LikePicsUIKit", targets: ["LikePicsUIKit"]),
        .library(name: "CompositeKit", targets: ["CompositeKit"]),
        .library(name: "Smoothie", targets: ["Smoothie"]),
        .library(name: "Common", targets: ["Common"]),
        .library(name: "Environment", targets: ["Environment"]),
        .library(name: "TestHelper", targets: ["TestHelper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/phimage/Erik", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/tasuwo/PersistentStack", .upToNextMajor(from: "0.8.1")),
        .package(url: "https://github.com/tasuwo/MasonryGrid", .upToNextMajor(from: "0.0.1-alpha.6")),
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/realm/realm-swift", .upToNextMajor(from: "10.54.5")),
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
                "ClipCreationFeatureCore",
                "ClipPreviewPlayConfigurationModalFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie",
                "MobileTransition",
                .product(name: "PersistentStack", package: "PersistentStack"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "AppDesktopFeature",
            dependencies: [
                "Domain",
                "Persistence",
                .product(name: "MasonryGrid", package: "MasonryGrid"),
                .product(name: "PersistentStack", package: "PersistentStack"),
            ],
        ),
        .target(
            name: "ShareExtensionMobileFeature",
            dependencies: [
                "Common",
                "Domain",
                "AlbumMultiSelectionModalFeature",
                "ClipCreationFeature",
                "ClipCreationFeatureCore",
                "TagSelectionModalFeature",
                "LikePicsUIKit",
                "Persistence",
                "Smoothie",
                "ShareExtensionFeatureCore",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
        ),
        .target(
            name: "ShareExtensionDesktopFeature",
            dependencies: [
                "Persistence",
                "Smoothie",
                "ShareExtensionFeatureCore",
                "ClipCreationDesktopFeature",
                "ClipCreationFeatureCore",
                .product(name: "PersistentStack", package: "PersistentStack"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "ShareExtensionFeatureCore",
            dependencies: [
                "ClipCreationFeatureCore"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
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
                "CompositeKit",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
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
                "CompositeKit",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
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
                "CompositeKit",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
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
                "ClipCreationFeatureCore",
                .product(name: "Erik", package: "Erik"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "ClipCreationDesktopFeature",
            dependencies: [
                "Persistence",
                "Smoothie",
                "ClipCreationFeatureCore",
                .product(name: "MasonryGrid", package: "MasonryGrid"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "ClipCreationFeatureCore",
            dependencies: [
                "Domain",
                "Common",
                .product(name: "Erik", package: "Erik"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "ClipPreviewPlayConfigurationModalFeature",
            dependencies: [
                "LikePicsUIKit",
                "Domain",
                "Environment",
                "Common",
                "CompositeKit",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),

        // MARK: - Core

        .target(
            name: "Domain",
            dependencies: [
                "Common",
                "Smoothie",
            ]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                "TestHelper",
            ]
        ),
        .target(
            name: "Environment",
            dependencies: [
                "Common",
                "Domain",
                "Smoothie",
                "MobileTransition",
            ]
        ),
        .target(
            name: "MobileTransition"
        ),

        // MARK: - Persistence

        .target(
            name: "Persistence",
            dependencies: [
                "Common",
                "Domain",
                .product(name: "RealmSwift", package: "realm-swift"),
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                "TestHelper",
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
                "MobileTransition",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),

        // MARK: - Helper

        .target(
            name: "CompositeKit",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "Smoothie",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .target(
            name: "Common"
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
                "LikePicsUIKit",
            ]
        ),
    ]
)
