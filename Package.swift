// swift-tools-version:5.9
import PackageDescription

let package = Package(
	name: "Defaults",
	platforms: [
		.macOS(.v11),
		.iOS(.v14),
		.tvOS(.v14),
		.watchOS(.v7),
		.visionOS(.v1)
	],
	products: [
		.library(
			name: "Defaults",
			targets: [
				"Defaults"
			]
		)
	],
	targets: [
		.target(
			name: "Defaults"
		),
		.testTarget(
			name: "DefaultsTests",
			dependencies: [
				"Defaults"
			]
		)
	]
)
