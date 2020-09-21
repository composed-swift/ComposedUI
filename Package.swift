// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "ComposedUI",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ComposedUI",
            targets: ["ComposedUI"]),
    ],
    dependencies: [
        .package(name: "Composed", url: "https://github.com/composed-swift/composed", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ComposedUI",
            dependencies: ["Composed"]),
        .testTarget(
            name: "ComposedUITests",
            dependencies: ["Composed", "ComposedUI"]),
    ]
)
