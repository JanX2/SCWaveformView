// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SCWaveformView",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SCWaveformView",
            targets: ["SCWaveformView"]
        ),
    ],
    targets: [
        .target(
            name: "SCWaveformView",
            path: "spm_sources"
        )
    ]
)
