// swift-tools-version:5.11
import PackageDescription

let package = Package(
	name: "Defaults",
	platforms: [
		.macOS(.v11),
		.iOS(.v14),
		.tvOS(.v14),
		.watchOS(.v9),
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
			name: "Defaults",
			resources: [.copy("PrivacyInfo.xcprivacy")]
		),
		.testTarget(
			name: "DefaultsTests",
			dependencies: [
				"Defaults"
			]
		)
	]
)
