# SampleIosFramework — modules shipped as source **and** binary

A demonstration of building two Swift modules, grouping them into two products,
and distributing each product in **both source and pre-compiled binary** form via
Swift Package Manager (SPM).

- Repository: <https://github.com/amitkumar0000/sampleios>
- Package: `Modules/SampleModules`
- The existing `FreeAPISample` iOS app in this repo is left untouched.

---

## 1. Modules and products

| Module (target) | Source path                     | Description                    |
|-----------------|---------------------------------|--------------------------------|
| `Network`       | `Modules/SampleModules/Sources/Network` | `URLSession`-based HTTP client |
| `Logger`        | `Modules/SampleModules/Sources/Logger`  | Small leveled logging utility  |

| Product    | Targets            | Distributed as                |
|------------|--------------------|-------------------------------|
| `ProductA` | `Network`, `Logger`| source **and** binary         |
| `ProductB` | `Network`          | source **and** binary         |

A product is just a **collection of module targets** (there is no umbrella
module). Consumers always `import Network` / `import Logger`; only the *kind* of
package dependency changes between source and binary mode.

---

## 2. Requirements

- Xcode 15+ (validated here with Xcode 27 / Swift 6.4)
- iOS 15.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — only to regenerate the
  binary project: `brew install xcodegen`
- [GitHub CLI](https://cli.github.com) — to publish releases:
  `brew install gh && gh auth login`

---

## 3. Repository layout

```
sampleios/
├── FreeAPISample/ ...            # existing sample app (unchanged)
├── Modules/SampleModules/        # the Swift package
│   ├── Package.swift             # SOURCE manifest
│   ├── Sources/{Network,Logger}/ # module sources
│   ├── Tests/{NetworkTests,LoggerTests}/
│   ├── project.yml               # XcodeGen spec for the binary project
│   ├── SampleModules.xcodeproj   # generated (only used to build xcframeworks)
│   └── Distribution/
│       ├── Package.swift.template # BINARY manifest template
│       └── README.binary.md
├── scripts/
│   ├── build-xcframeworks.sh     # build Network/Logger .xcframework + zip
│   └── release.sh                # build + publish branches + GitHub Release
└── .github/workflows/release.yml # CI release on tag / manual dispatch
```

### Published branches (created by `scripts/release.sh`)

| Branch   | Root `Package.swift`          | Consume with                                  |
|----------|-------------------------------|-----------------------------------------------|
| `main`   | none (app + package source)   | n/a (authoring)                               |
| `source` | source manifest + `Sources/`  | `.package(url:, from: "1.0.0")`               |
| `binary` | `.binaryTarget` manifest      | `.package(url:, branch: "binary")`            |

> SPM requires `Package.swift` at the **root** of a repository for a remote
> dependency. Because the package is authored in a subfolder here, the release
> script publishes it to the root of the `source` / `binary` branches.

---

## 4. The `Package.swift` (source) — step by step

Full file: `Modules/SampleModules/Package.swift`

```swift
// swift-tools-version:5.9          // minimum toolchain feature set
import PackageDescription            // always import PackageDescription

let package = Package(
    name: "SampleModules",           // package name (used in `.product(package:)`)

    platforms: [
        .iOS(.v15)                   // minimum platform(s)
    ],

    products: [
        // A product is a set of targets that a consumer can depend on.
        .library(name: "ProductA", targets: ["Network", "Logger"]),
        .library(name: "ProductB", targets: ["Network"])
    ],

    targets: [
        .target(name: "Network"),                       // source module
        .target(name: "Logger"),                        // source module

        .testTarget(name: "NetworkTests", dependencies: ["Network"]),
        .testTarget(name: "LoggerTests",  dependencies: ["Logger"])
    ]
)
```

Key points:

1. **`name`** — the package identifier; consumers reference it in
   `.product(name: "ProductA", package: "SampleModules")` (case-insensitive).
2. **`platforms`** — SwiftPM checks this when a consumer resolves the package.
3. **`products`** — what consumers import. `ProductA` bundles **both** module
   targets; `ProductB` bundles **only** `Network`.
4. **`targets`** — the actual modules. Each `.target` maps to a folder under
   `Sources/<Name>` by default.
5. **`testTarget`** — unit tests; run with `swift test`.

### Adding a module

1. Create `Sources/NewModule/` with Swift files.
2. Add `.target(name: "NewModule")` to `targets`.
3. Add `"NewModule"` to whichever `products` should ship it.
4. Re-run `xcodegen generate` so the binary project picks it up (and add the
   target to `project.yml`).

---

## 5. Local development

```bash
cd Modules/SampleModules
swift build
swift test
```

---

## 6. Consume — **Source mode**

Everything is compiled from source in the consumer's build.

**Xcode:** `File ▸ Add Package Dependencies…` → `https://github.com/amitkumar0000/sampleios.git`
→ *Dependency Rule*: **Up to Next Major** from `1.0.0` (or choose branch `source`).

**`Package.swift` of the consumer:**

```swift
dependencies: [
    .package(url: "https://github.com/amitkumar0000/sampleios.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "ProductA", package: "SampleModules")   // Network + Logger
        // .product(name: "ProductB", package: "SampleModules") // Network only
    ])
]
```

```swift
import Network
import Logger
```

---

## 7. Build the XCFrameworks

```bash
./scripts/build-xcframeworks.sh
```

Produces, in `Modules/SampleModules/dist/`:

```
Network.xcframework/          Logger.xcframework/
Network.xcframework.zip       Logger.xcframework.zip
```

Each xcframework contains:

- `ios-arm64` — physical devices
- `ios-arm64_x86_64-simulator` — Apple-silicon and Intel simulators

They are built with `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` (library evolution) and
`MACH_O_TYPE=staticlib` (static frameworks).

---

## 8. The binary `Package.swift` (rendered by `release.sh`)

Template: `Modules/SampleModules/Distribution/Package.swift.template`

```swift
// swift-tools-version:5.9
import PackageDescription

let version = "1.0.0"
let baseURL = "https://github.com/amitkumar0000/sampleios/releases/download/\(version)"

let package = Package(
    name: "SampleModules",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ProductA", targets: ["Network", "Logger"]),
        .library(name: "ProductB", targets: ["Network"])
    ],
    targets: [
        .binaryTarget(
            name: "Network",
            url: "\(baseURL)/Network.xcframework.zip",
            checksum: "…"
        ),
        .binaryTarget(
            name: "Logger",
            url: "\(baseURL)/Logger.xcframework.zip",
            checksum: "…"
        )
    ]
)
```

The difference from source mode: `.target` becomes `.binaryTarget`, which points
at a `*.xcframework.zip` URL plus its checksum. Products are unchanged.

---

## 9. Consume — **Binary mode**

```swift
dependencies: [
    .package(url: "https://github.com/amitkumar0000/sampleios.git", branch: "binary")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "ProductA", package: "SampleModules")
    ])
]
```

```swift
import Network   // same imports as source mode
import Logger
```

---

## 10. Publish a release

```bash
# requires: brew install gh && gh auth login
./scripts/release.sh 1.0.0
```

What it does:

1. Runs `scripts/build-xcframeworks.sh`.
2. `swift package compute-checksum` for each zip.
3. Renders the binary manifest from the template.
4. Force-pushes the `source` branch + creates tag `1.0.0`.
5. Force-pushes the `binary` branch.
6. `gh release create 1.0.0` and uploads `Network.xcframework.zip` and
   `Logger.xcframework.zip`.

### Checksums manually

```bash
swift package compute-checksum Modules/SampleModules/dist/Network.xcframework.zip
```

Paste the output into the `.binaryTarget(checksum:)` of the binary manifest.

### CI

`.github/workflows/release.yml` does the same on a tag push (`1.0.0`) or via
**Actions ▸ Release ▸ Run workflow**. It uses the built-in `GITHUB_TOKEN`
(`contents: write`), so no extra secrets are needed.

---

## 11. Source vs binary — parity

| Concern              | Source mode                    | Binary mode                          |
|----------------------|--------------------------------|--------------------------------------|
| Dependency           | `from: "1.0.0"` (`source`)     | `branch: "binary"`                   |
| Manifest targets     | `.target`                      | `.binaryTarget` (+ `url`/`checksum`) |
| Products             | `ProductA` / `ProductB`        | `ProductA` / `ProductB`              |
| Imports              | `import Network` / `Logger`    | `import Network` / `Logger`          |
| Compile time         | built by consumer              | pre-compiled                         |
| Source visibility    | full source                    | headers/module only                  |

Switching modes changes **only the package dependency** — application code and
imports stay identical.

---

## 12. Troubleshooting

- **SPM can't find a package in a subfolder** — remote dependencies need
  `Package.swift` at the repo root. Use the `source` / `binary` branches.
- **`checksum` mismatch** — rebuild, recompute with
  `swift package compute-checksum`, and update the manifest.
- **Missing simulator slice** — rebuild with
  `ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO` (handled by the build script).
- **Resolution picks the wrong ref** — use `from:`/`exact:` for the tagged
  `source` branch and `branch: "binary"` for binary.
- **Tag rejected by SPM** — use plain semver tags (`1.0.0`), not `v1.0.0`.

---

## 13. Release checklist

- [ ] Bump/choose a version (plain semver, e.g. `1.1.0`).
- [ ] `cd Modules/SampleModules && swift test` is green.
- [ ] `./scripts/build-xcframeworks.sh` succeeds.
- [ ] `gh auth status` is authenticated.
- [ ] Run `./scripts/release.sh <version>`.
- [ ] Verify the GitHub Release and the `source` / `binary` branches.
