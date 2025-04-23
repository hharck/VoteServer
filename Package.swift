// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "VoteServer",
	platforms: [
		.macOS(.v13)
	],
	dependencies: [
		// 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.111.0"),
		.package(url: "https://github.com/vapor/leaf.git", from: "4.4.1"),
		// Fluent
		.package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
		.package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.0"),
		// VoteKit definitions
        .package(url: "https://github.com/hharck/VoteKit", "0.6.5"..<"0.7.0"),
		.package(url: "https://github.com/hharck/AltVoteKit", "0.6.3"..<"0.7.0"),
		// VoteExchangeFormat, defines API protocols
		.package(url: "https://github.com/hharck/VoteExchangeFormat", branch: "main"),
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "Leaf", package: "leaf"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Fluent", package: "fluent"),
				.product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
				.product(name: "AltVoteKit", package: "AltVoteKit"),
				.product(name: "VoteKit", package: "VoteKit"),
				.product(name: "VoteExchangeFormat", package: "VoteExchangeFormat")
				
			],
			swiftSettings: [
				// Enable better optimizations when building in Release configuration. Despite the use of
				// the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
				// builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
				.unsafeFlags(["-Xfrontend", "-warn-long-function-bodies=40", "-Xfrontend", "-warn-long-expression-type-checking=40"])
			]
		),
		.executableTarget(name: "Run", dependencies: [.target(name: "App")]),
		.testTarget(name: "AppTests", dependencies: [
			.target(name: "App"),
			.product(name: "XCTVapor", package: "vapor"),
		])
	]
)
