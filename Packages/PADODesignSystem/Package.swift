// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PADODesignSystem",
  defaultLocalization: "ko",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "PADODesignSystem", targets: ["PADODesignSystem"]),
  ],
  targets: [
    .target(name: "PADODesignSystem"),
    .testTarget(name: "PADODesignSystemTests", dependencies: ["PADODesignSystem"]),
  ]
)
