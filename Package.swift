// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReFUSE",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ReFUSE",
            path: "Sources/ReFUSE",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreFoundation")
            ]
        )
    ]
)
