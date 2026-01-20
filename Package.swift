// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-async-observer",
    platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16)],
    products: [
        .library(name: "AsyncObserver", targets: ["AsyncObserver"])
    ],
    targets: [
        .target(
            name: "AsyncObserver"
        ),
        .testTarget(
            name: "AsyncObserverTests",
            dependencies: ["AsyncObserver"]
        )
    ]
)
