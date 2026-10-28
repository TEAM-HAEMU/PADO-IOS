// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PADOKit",
  defaultLocalization: "ko",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "PADOKit", targets: ["PADOKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
  ],
  targets: [
    .target(
      name: "PADOKit",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
      ],
      resources: [.process("Resources")]
    ),
    .testTarget(name: "PADOKitTests", dependencies: ["PADOKit"]),
  ]
)
