import Foundation
import XCTest
import Defaults

let fixtureURL = URL(string: "https://sindresorhus.com")!
let fixtureURL2 = URL(string: "https://example.com")!

enum FixtureEnum: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

let fixtureDate = Date()

extension Defaults.Keys {
	static let key = Key<Bool>("key", default: false)
	static let url = Key<URL>("url", default: fixtureURL)
	static let `enum` = Key<FixtureEnum>("enum", default: .oneHour)
	static let data = Key<Data>("data", default: Data(bytes: []))
	static let date = Key<Date>("date", default: fixtureDate)
}

final class DefaultsTests: XCTestCase {
	override func setUp() {
		super.setUp()
		defaults.clear()
	}

	override func tearDown() {
		super.setUp()
		defaults.clear()
	}

	func testKey() {
		let key = Defaults.Key<Bool>("independentKey", default: false)
		XCTAssertFalse(defaults[key])
		defaults[key] = true
		XCTAssertTrue(defaults[key])
	}

	func testOptionalKey() {
		let key = Defaults.OptionalKey<Bool>("independentOptionalKey")
		XCTAssertNil(defaults[key])
		defaults[key] = true
		XCTAssertTrue(defaults[key]!)
		defaults[key] = nil
		XCTAssertNil(defaults[key])
		defaults[key] = false
		XCTAssertFalse(defaults[key]!)
	}

	func testKeyWithUserDefaultSubscript() {
		let key = Defaults.Key<Bool>("keyWithUserDeaultSubscript", default: false)
		XCTAssertFalse(UserDefaults.standard[key])
		UserDefaults.standard[key] = true
		XCTAssertTrue(UserDefaults.standard[key])
	}

	func testKeys() {
		XCTAssertFalse(defaults[.key])
		defaults[.key] = true
		XCTAssertTrue(defaults[.key])
	}

	func testUrlType() {
		XCTAssertEqual(defaults[.url], fixtureURL)

		let newUrl = URL(string: "https://twitter.com")!
		defaults[.url] = newUrl
		XCTAssertEqual(defaults[.url], newUrl)
	}

	func testEnumType() {
		XCTAssertEqual(defaults[.enum], FixtureEnum.oneHour)
	}

	func testDataType() {
		XCTAssertEqual(defaults[.data], Data(bytes: []))

		let newData = Data(bytes: [0xFF])
		defaults[.data] = newData
		XCTAssertEqual(defaults[.data], newData)
	}

	func testDateType() {
		XCTAssertEqual(defaults[.date], fixtureDate)

		let newDate = Date()
		defaults[.date] = newDate
		XCTAssertEqual(defaults[.date], newDate)
	}

	func testClear() {
		let key = Defaults.Key<Bool>("clear", default: false)
		defaults[key] = true
		XCTAssertTrue(defaults[key])
		defaults.clear()
		XCTAssertFalse(defaults[key])
	}

	func testCustomSuite() {
		let customSuite = UserDefaults(suiteName: "com.sindresorhus.customSuite")!
		let key = Defaults.Key<Bool>("customSuite", default: false, suite: customSuite)
		XCTAssertFalse(customSuite[key])
		XCTAssertFalse(defaults[key])
		defaults[key] = true
		XCTAssertTrue(customSuite[key])
		XCTAssertTrue(defaults[key])
		defaults.clear(suite: customSuite)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bool>("observeKey", default: false)

		// Using `weak` here to prevent `.fullfill()` to be called multiple times, since the callback is called multiple times on Travis CI for some reason. Not reproducible locally.
		weak var expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertFalse(change.oldValue)
			XCTAssertTrue(change.newValue)
			expect?.fulfill()
			expect = nil
			observation.invalidate()
		}

		defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.OptionalKey<Bool>("observeOptionalKey")
		weak var expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertTrue(change.newValue!)
			expect?.fulfill()
			expect = nil
			observation.invalidate()
		}

		defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	func testObserveKeyURL() {
		let fixtureURL = URL(string: "https://sindresorhus.com")!
		let fixtureURL2 = URL(string: "https://example.com")!
		let key = Defaults.Key<URL>("observeKeyURL", default: fixtureURL)
		weak var expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertEqual(change.oldValue, fixtureURL)
			XCTAssertEqual(change.newValue, fixtureURL2)
			expect?.fulfill()
			expect = nil
			observation.invalidate()
		}

		defaults[key] = fixtureURL2

		waitForExpectations(timeout: 10)
	}

	func testObserveKeyEnum() {
		let key = Defaults.Key<FixtureEnum>("observeKeyEnum", default: .oneHour)
		weak var expect = expectation(description: "Observation closure being called")

		var observation: DefaultsObservation!
		observation = defaults.observe(key, options: [.old, .new]) { change in
			XCTAssertEqual(change.oldValue, .oneHour)
			XCTAssertEqual(change.newValue, .tenMinutes)
			expect?.fulfill()
			expect = nil
			observation.invalidate()
		}

		defaults[key] = .tenMinutes

		waitForExpectations(timeout: 10)
	}
}
