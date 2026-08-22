// swift-tools-version: 6.0

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
        ),
        .testTarget(
            name: "KlarfolioPDFEditorTests",
            dependencies: ["KlarfolioPDFEditor"],
            path: "Tests/KlarfolioPDFEditorTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
