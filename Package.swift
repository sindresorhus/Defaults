// swift-tools-version:5.7
import PackageDescription

let package = Package(
	name: "Defaults",
	platforms: [
		.macOS(.v10_13),
		.iOS(.v12),
		.tvOS(.v12),
		.watchOS(.v5)
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
