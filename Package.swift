// swift-tools-version:5.0
import PackageDescription

let package = Package(
	name: "Defaults",
	platforms: [
		.macOS(.v10_12),
		.iOS(.v10),
		.tvOS(.v10),
		.watchOS(.v3)
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
			name: "Defaults",
            path: "Sources"
		),
		.testTarget(
			name: "DefaultsTests",
			dependencies: [
				"Defaults"
			]
		)
	]
)
