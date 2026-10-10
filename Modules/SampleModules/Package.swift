// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SampleModules",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // ProductA ships BOTH the Network and Logger modules.
        .library(name: "ProductA", targets: ["Network", "Logger"]),

        // ProductB ships ONLY the Network module.
        .library(name: "ProductB", targets: ["Network"])
    ],
    targets: [
        .target(name: "Network"),
        .target(name: "Logger"),

        .testTarget(name: "NetworkTests", dependencies: ["Network"]),
        .testTarget(name: "LoggerTests", dependencies: ["Logger"])
    ]
)
