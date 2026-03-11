// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScannerPlugins",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ScannerPlugins",
            targets: ["ScannerPlugins"]
        )
    ],
    targets: [
        .target(
            name: "ScannerPlugins",
            path: "Sources/ScannerPlugins"
        ),
        .testTarget(
            name: "ScannerPluginsTests",
            dependencies: ["ScannerPlugins"]
        )
    ]
)
