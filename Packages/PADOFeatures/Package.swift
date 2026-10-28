// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PADOFeatures",
  defaultLocalization: "ko",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "PADOFeatures", targets: ["PADOFeatures"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.25.5"),
    .package(path: "../PADOKit"),
    .package(path: "../PADODesignSystem"),
  ],
  targets: [
    .target(
      name: "PADOFeatures",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "PADOKit",
        "PADODesignSystem",
      ]
    ),
    .testTarget(name: "PADOFeaturesTests", dependencies: ["PADOFeatures"]),
  ]
)
