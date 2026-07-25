// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "EgressEngine",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "EgressEngine", targets: ["EgressEngine"]),
    ],
    targets: [
        .target(name: "EgressEngine"),
        .testTarget(name: "EgressEngineTests", dependencies: ["EgressEngine"]),
    ]
)