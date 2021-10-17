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
            name: "ForestKit",
            targets: ["ForestKit"]
        ),
        .library(
            name: "Smoothie",
            targets: ["Smoothie"]
        ),
        .library(
            name: "Common",
            targets: ["Common"]
        ),
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa", .exact("10.15.1")),
        .package(name: "Erik", url: "https://github.com/phimage/Erik", .exact("5.1.0")),
        .package(name: "Quick", url: "https://github.com/Quick/Quick", .exact("4.0.0")),
        .package(name: "Nimble", url: "https://github.com/Quick/Nimble", .exact("9.2.1"))
    ],
    targets: [
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
                .product(name: "RealmSwift", package: "Realm"),
            ]
        ),
        .target(
            name: "LikePicsCore",
            dependencies: [
                "LikePicsUIKit",
                "Smoothie",
                "Domain",
                "Common",
                "ForestKit",
                .product(name: "Erik", package: "Erik")
            ]
        ),
        .target(
            name: "LikePicsUIKit",
            dependencies: [
                "Smoothie",
                "Domain",
                "Common",
                "ForestKit",
            ]
        ),
        .target(
            name: "ForestKit",
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
            name: "TestHelper",
            dependencies: [
                "Persistence",
                "LikePicsUIKit"
            ]
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                "TestHelper",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: [
                "Persistence",
                "TestHelper",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble")
            ],
            resources: [
                .process("Resources/")
            ]
        ),
    ]
)
