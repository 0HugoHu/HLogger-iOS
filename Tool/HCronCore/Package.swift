// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HCronCore",
    products: [
        .library(
            name: "HCronCore",
            targets: ["HCronCore"]),
    ],
    targets: [
        .target(
            name: "HCronCore",
            resources: [
                .process("Resources")
            ]),
    ]
)
