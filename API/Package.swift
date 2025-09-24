// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "API",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/GetAutomaApp/SwiftWebDriver.git", branch: "master"),
        .package(url: "https://github.com/GetAutomaApp/AutomaUtilities.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "API",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "SwiftWebDriver", package: "SwiftWebDriver"),
                .product(name: "AutomaUtilities", package: "AutomaUtilities")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "APITests",
            dependencies: [
                .target(name: "API"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
