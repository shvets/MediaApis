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
    .library(name: "MediaApis", targets: ["MediaApis"])
    //.executable(name: "grabbook", targets: ["GrabBook"])
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "4.3.1"),
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.0.0"),
    .package(url: "https://github.com/JohnSundell/Files", from: "3.1.0"),
    .package(path: "../SimpleHttpClient")
  ],
  targets: [
    .target(
      name: "MediaApis",
      dependencies: [
        "SimpleHttpClient",
        "RxSwift",
        "SwiftSoup",
        "Files"
      ]),
    //.target(
    //  name: "GrabBook",
    //  dependencies: [
    //    "MediaApis"
    //  ]),
    .testTarget(
      name: "MediaApisTests",
      dependencies: [
        "MediaApis"
      ]),
  ]
)
