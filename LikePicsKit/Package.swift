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
            name: "AppFeature",
            targets: ["AppFeature"]
        ),
        .library(
            name: "ShareExtensionFeature",
            targets: ["ShareExtensionFeature"]
        ),
        .library(
            name: "Domain",
            targets: ["Domain"]
        ),
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
        .library(
            name: "LikePicsCore",
            targets: ["LikePicsCore"]
        ),
        .library(
            name: "LikePicsUIKit",
            targets: ["LikePicsUIKit"]
        ),
        .library(
            name: "CompositeKit",
            targets: ["CompositeKit"]
        ),
        .library(
            name: "Smoothie",
            targets: ["Smoothie"]
        ),
        .library(
            name: "Common",
            targets: ["Common"]
        ),
        .library(
            name: "Environment",
            targets: ["Environment"]
        ),
        .library(
            name: "TestHelper",
            targets: ["TestHelper"]
        )
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa", .exact("10.15.1")),
        .package(name: "Erik", url: "https://github.com/phimage/Erik", .exact("5.1.0"))
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "Common",
                "CompositeKit",
                "Domain",
                "Environment",
                "LikePicsCore",
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
                "LikePicsCore",
                "Persistence",
                "Smoothie"
            ]
        ),
        .target(
            name: "Domain",
            dependencies: ["Common"]
        ),
        .target(
            name: "Persistence",
            dependencies: [
                "Common",
                "Domain",
                .product(name: "Realm", package: "Realm"),
                .product(name: "RealmSwift", package: "Realm")
            ]
        ),
        .target(
            name: "LikePicsCore",
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
            name: "LikePicsUIKit",
            dependencies: [
                "Smoothie",
                "Domain",
                "Common",
                "CompositeKit"
            ]
        ),
        .target(
            name: "CompositeKit",
            dependencies: []
        ),
        .target(
            name: "Smoothie",
            dependencies: []
        ),
        .target(
            name: "Common",
            dependencies: []
        ),
        .target(
            name: "Environment",
            dependencies: [
                "Common",
                "Domain",
                "LikePicsUIKit",
                "Smoothie"
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
                "LikePicsCore",
                "LikePicsUIKit"
            ]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                "TestHelper"
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
        )
    ]
)
