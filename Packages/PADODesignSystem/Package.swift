// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PADODesignSystem",
  defaultLocalization: "ko",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "PADODesignSystem", targets: ["PADODesignSystem"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.4"),
  ],
  targets: [
    .target(name: "PADODesignSystem", resources: [.process("Resources")]),
    .testTarget(
      name: "PADODesignSystemTests",
      dependencies: ["PADODesignSystem", .product(name: "SnapshotTesting", package: "swift-snapshot-testing")],
      exclude: ["__Snapshots__"]
    ),
  ]
)
