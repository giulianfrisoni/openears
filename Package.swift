// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "OpenEars",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "OpenEars", targets: ["OpenEars"])],
    dependencies: [.package(path: "Vendor/SwiftNothingEar")],
    targets: [
        .target(name: "OpenEarsCore", resources: [.copy("Resources/catalog.json"), .copy("Resources/ACKNOWLEDGMENTS.md")]),
        .executableTarget(name: "OpenEars", dependencies: ["OpenEarsCore", "SwiftNothingEar"]),
        .testTarget(name: "OpenEarsCoreTests", dependencies: ["OpenEarsCore"])
    ]
)
