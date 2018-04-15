import XCTest
import Defaults

let fixtureUrl = URL(string: "httos://sindresorhus.com")!

enum FixtureEnum: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension UserDefaults.Keys {
	static let key = UserDefaults.Key<Bool>("key", default: false)
	static let url = UserDefaults.Key<URL>("url", default: fixtureUrl)
	static let `enum` = UserDefaults.Key<FixtureEnum>("enum", default: .oneHour)
}

final class DefaultsTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.clear()
	}

	func testKey() {
		let key = UserDefaults.Key<Bool>("key", default: false)
		XCTAssertFalse(UserDefaults.standard[key])
		UserDefaults.standard[key] = true
		XCTAssertTrue(UserDefaults.standard[key])
	}

	func testOptionalKey() {
		let key = UserDefaults.OptionalKey<Bool>("key")
		XCTAssertNil(UserDefaults.standard[key])
		UserDefaults.standard[key] = true
		XCTAssertTrue(UserDefaults.standard[key]!)
	}

	func testKeys() {
		XCTAssertFalse(Defaults[.key])
		Defaults[.key] = true
		XCTAssertTrue(Defaults[.key])
	}

	func testUrlType() {
		XCTAssertEqual(Defaults[.url], fixtureUrl)

		let newUrl = URL(string: "https://twitter.com")!
		Defaults[.url] = newUrl
		XCTAssertEqual(Defaults[.url], newUrl)
	}

	func testEnumType() {
		XCTAssertEqual(Defaults[.enum], FixtureEnum.oneHour)
	}

	func testClear() {
		Defaults[.key] = true
		XCTAssertTrue(Defaults[.key])
		Defaults.clear()
		XCTAssertFalse(Defaults[.key])
	}
}
