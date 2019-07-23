// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ComposedUI",
    products: [
        .library(
            name: "ComposedUI",
            targets: ["ComposedUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/composed-swift/composed", from: "0.0.0"),
    ],
    targets: [
        .target(
            name: "ComposedUI",
            dependencies: ["Composed"])
    ]
)
