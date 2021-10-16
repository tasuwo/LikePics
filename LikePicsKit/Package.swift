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
            name: "ForestKit",
            targets: ["ForestKit"]
        ),
        .library(
            name: "Common",
            targets: ["Common"]
        ),
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa", .exact("10.15.1"))
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
            name: "ForestKit",
            dependencies: []
        ),
        .target(
            name: "Common",
            dependencies: []
        ),
        // TODO:
        // .testTarget(
        //     name: "DomainTests",
        //     dependencies: []
        // ),
        // TODO:
        // .testTarget(
        //     name: "PersistenceTests",
        //     dependencies: []
        // ),
    ]
)
