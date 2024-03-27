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
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "IoMT.SDK",
            exclude:["Observation-2.xcdatamodeld"]
            dependencies: [.product(name: "Reachability", package: "Reachability.swift")],
            path: "IoMT.SDK"
        )
    ],
    swiftLanguageVersions: [.v5]
)
