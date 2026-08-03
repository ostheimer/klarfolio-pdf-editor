// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KlarfolioPDFEditor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KlarfolioPDFEditor", targets: ["KlarfolioPDFEditor"])
    ],
    targets: [
        .executableTarget(
            name: "KlarfolioPDFEditor",
            path: "Sources/KlarfolioPDFEditor",
            exclude: ["Resources"]
        )
    ]
)
