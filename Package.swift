// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "MediaApis",
  platforms: [
    .macOS(.v10_12),
    .iOS(.v10),
    .tvOS(.v10)
  ],
  products: [
    .library(name: "MediaApis", targets: ["MediaApis"]),
    .executable(name: "grabbook", targets: ["GrabBook"])
  ],
  dependencies: [
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.3.0"),
    .package(url: "https://github.com/JohnSundell/Files", from: "4.1.1"),
    .package(url: "https://github.com/JohnSundell/Codextended", from: "0.3.0"),
    .package(path: "../SimpleHttpClient"),
    .package(path: "../Await")
  ],
  targets: [
    .target(
      name: "MediaApis",
      dependencies: [
        "SwiftSoup",
        "Files",
        "Codextended",
        "SimpleHttpClient"
      ]),
    .target(
      name: "GrabBook",
      dependencies: [
        "MediaApis"
      ]),
    .testTarget(
      name: "MediaApisTests",
      dependencies: [
        "MediaApis"
      ]),
  ]
)
