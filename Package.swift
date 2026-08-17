// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuanSweep",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "QuanSweep",
            targets: ["QuanSweep"]
        )
    ],
    targets: [
        .executableTarget(
            name: "QuanSweep",
            path: "Sources/QuanSweep",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
