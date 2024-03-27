// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "IoMT.SDK",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(
            name: "IoMT.SDK",
            targets: ["IoMT.SDK"]
        )
    ],
    dependencies: [
 
    ],
    targets: [
        .target(
            name: "IoMT.SDK",
            dependencies: [],
            path: "IoMT.SDK"
        )
    ],
    swiftLanguageVersions: [.v5]
)
