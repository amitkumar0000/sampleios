// swift-tools-version:5.9
//
// BINARY distribution manifest for the SampleModules package.
//
// This file is a TEMPLATE. scripts/release.sh fills in the placeholders
// (1.0.0, 571b1c265ecde526b9a8bdcf4af83e352e70d7a651d350b889b63e6a9433a556, e7f9ad0a11f6d8d87c21546f378faf5eca81fae30711af6ee8eea48bd52bb5ad) and publishes the
// result as `Package.swift` on the `binary` branch.
//
// Consumers of the `binary` branch get ProductA / ProductB as pre-compiled
// XCFrameworks instead of source. The modules and imports are identical to the
// source package.
//
import PackageDescription

let version = "1.0.0"
let baseURL = "https://github.com/amitkumar0000/sampleios/releases/download/\(version)"

let package = Package(
    name: "SampleModules",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // ProductA ships BOTH modules (Network + Logger) as binaries.
        .library(name: "ProductA", targets: ["Network", "Logger"]),

        // ProductB ships ONLY the Network module as a binary.
        .library(name: "ProductB", targets: ["Network"])
    ],
    targets: [
        .binaryTarget(
            name: "Network",
            url: "\(baseURL)/Network.xcframework.zip",
            checksum: "571b1c265ecde526b9a8bdcf4af83e352e70d7a651d350b889b63e6a9433a556"
        ),
        .binaryTarget(
            name: "Logger",
            url: "\(baseURL)/Logger.xcframework.zip",
            checksum: "e7f9ad0a11f6d8d87c21546f378faf5eca81fae30711af6ee8eea48bd52bb5ad"
        )
    ]
)
