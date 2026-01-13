// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "DVR",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
          name: "DVR",
          targets: ["DVR"])
    ],
    targets: [
      .target(name: "DVR"),
      .testTarget(
          name: "DVRTests",
          dependencies: ["DVR"])
    ]
)

