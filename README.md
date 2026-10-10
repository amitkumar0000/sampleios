# SampleModules

A Swift Package with two independent modules and two products.

| Module (target) | Description                          |
|-----------------|--------------------------------------|
| `Network`       | `URLSession`-based HTTP client       |
| `Logger`        | Small leveled logging utility        |

| Product    | Targets shipped  |
|------------|------------------|
| `ProductA` | `Network`, `Logger` |
| `ProductB` | `Network`        |

Products are **collections of module targets** — there is no umbrella module.
Consumers `import Network` and/or `import Logger` directly.

## Package.swift

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SampleModules",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ProductA", targets: ["Network", "Logger"]),
        .library(name: "ProductB", targets: ["Network"])
    ],
    targets: [
        .target(name: "Network"),
        .target(name: "Logger"),
        .testTarget(name: "NetworkTests", dependencies: ["Network"]),
        .testTarget(name: "LoggerTests", dependencies: ["Logger"])
    ]
)
```

## Develop & test

```bash
swift build
swift test
```

## Regenerate the binary Xcode project

`SampleModules.xcodeproj` exists only to build the XCFrameworks (it shares these
same sources). It is generated from `project.yml`:

```bash
brew install xcodegen
xcodegen generate
```

See the repository root `README.md` for the full source/binary distribution guide.
