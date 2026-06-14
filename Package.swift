// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OpenPDF",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "OpenPDF", targets: ["OpenPDF"])
    ],
    targets: [
        .executableTarget(
            name: "OpenPDF",
            path: "Sources/OpenPDF"
        )
    ]
)
