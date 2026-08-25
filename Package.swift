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
        .target(
            name: "KlarfolioPDFTestFixtures",
            path: "TestFixtures",
            exclude: ["README.md"],
            resources: [
                .copy("fixture-text-3-pages.pdf"),
                .copy("fixture-outline-4-pages.pdf"),
                .copy("fixture-merge-2-pages.pdf"),
                .copy("fixture-form.pdf"),
                .copy("fixture-invalid.pdf")
            ]
        ),
        .executableTarget(
            name: "KlarfolioPDFEditor",
            path: "Sources/KlarfolioPDFEditor",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "KlarfolioPDFEditorTests",
            dependencies: ["KlarfolioPDFEditor", "KlarfolioPDFTestFixtures"],
            path: "Tests/KlarfolioPDFEditorTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
