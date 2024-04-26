// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IrisCamera",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "IrisCamera",
            targets: ["IrisCamera"]),
    ],
    targets: [
        .target(
            name: "IrisCamera")
    ]
)
