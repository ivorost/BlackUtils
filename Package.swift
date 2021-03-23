// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlackUtils",
    platforms: [
        .macOS(.v10_11),
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "BlackUtils",
            targets: ["BlackUtils"]
        )
    ],
    targets: [
        .target(
            name: "BlackUtils",
            path: "Apple"
        )
    ]
)
