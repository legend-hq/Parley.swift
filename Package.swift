// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parley",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .library(
            name: "Prelude",
            targets: ["Prelude"]
        ),
        .library(
            name: "Charter",
            targets: ["Charter"]
        ),
        .executable(
            name: "Parley",
            targets: ["Parley"]
        ),
        .library(
            name: "Portfolio",
            targets: ["Portfolio"]
        ),
        .library(
            name: "Tradewinds",
            targets: ["Tradewinds"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/GoodNotes/swift-icudata-slim.git", from: "0.2.0"),
        .package(
            url: "https://github.com/hayesgm/Eth.swift",
            exact: "1.0.4"
        ),
        .package(
            url: "git@github.com:legend-hq/SwiftNumber",
            exact: "1.0.0"
        ),
        .package(
            path: "../Atlas.swift"
        ),
        .package(
            url: "https://github.com/hayesgm/SwiftKeccak.git",
            exact: "1.0.0"
        ),
    ],
    targets: [
        .target(
            name: "Tradewinds",
            dependencies: [
                "Prelude",
                .product(name: "SwiftNumber", package: "SwiftNumber"),
            ],
            path: "Sources/Tradewinds"
        ),
        .target(
            name: "Prelude",
            dependencies: [
                .product(name: "Eth", package: "Eth.swift"),
                .product(name: "SwiftNumber", package: "SwiftNumber"),
                .product(name: "Atlas", package: "Atlas.swift"),
                .product(name: "SwiftKeccak", package: "SwiftKeccak"),
            ],
            path: "Sources/Prelude"
        ),
        .target(
            name: "Portfolio",
            dependencies: [
                "Prelude",
                "Charter",
                .product(name: "Eth", package: "Eth.swift"),
                .product(name: "SwiftNumber", package: "SwiftNumber"),
                .product(name: "Atlas", package: "Atlas.swift"),
            ],
            path: "Sources/Portfolio"
        ),
        .target(
            name: "Charter",
            dependencies: [
                "Prelude",
                "Tradewinds",
                .product(name: "Eth", package: "Eth.swift"),
                .product(name: "SwiftNumber", package: "SwiftNumber"),
                .product(name: "Atlas", package: "Atlas.swift"),
            ],
            path: "Sources/Charter"
        ),
        .executableTarget(
            name: "Parley",
            dependencies: [
                "Charter",
                "Portfolio",
                .product(name: "Eth", package: "Eth.swift"),
                .product(name: "ICUDataSlim", package: "swift-icudata-slim"),
            ],
            path: "Sources/Parley"
        ),
        .testTarget(
            name: "AcceptanceTests",
            dependencies: ["Charter", "TestHelpers"],
            path: "Tests/AcceptanceTests",
        ),
        .testTarget(
            name: "CharterTests",
            dependencies: ["Charter", "TestHelpers"],
            path: "Tests/CharterTests"
        ),
        .testTarget(
            name: "PreludeTests",
            dependencies: ["Prelude", "TestHelpers"],
            path: "Tests/PreludeTests"
        ),
        .testTarget(
            name: "PortfolioTests",
            dependencies: ["Portfolio", "TestHelpers"],
            path: "Tests/PortfolioTests"
        ),
        .testTarget(
            name: "TestHelpers",
            dependencies: ["Charter", "Portfolio"],
            path: "Tests/TestHelpers"
        ),
        .testTarget(
            name: "TradewindsTests",
            dependencies: [
                .byName(name: "Tradewinds"),
                .byName(name: "Charter"),
                .byName(name: "TestHelpers"),
            ],
            path: "Tests/TradewindsTests"
        ),
        .testTarget(
            name: "HarnessTests",
            dependencies: [
                "Charter",
                "TestHelpers",
            ],
            path: "Tests/HarnessTests",
            resources: [
                .process("HarnessTests.json")
            ]
        ),
    ]
)
