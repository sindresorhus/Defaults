import Foundation
import Defaults
import XCTest

enum FixtureCodableEnum: String, Codable, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let `codable_enum` = Key<FixtureCodableEnum>("codable_enum", default: .oneHour)
}


final class DefaultsCodableEnumTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<FixtureCodableEnum>("independentCodableKey", default: .tenMinutes)
		XCTAssertEqual(Defaults[key], .tenMinutes)
		Defaults[key] = .halfHour
		XCTAssertEqual(Defaults[key], .halfHour)
	}

	func testOptionalKey() {
		let key = Defaults.Key<FixtureCodableEnum?>("independentCodableOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = .tenMinutes
		XCTAssertEqual(Defaults[key], .tenMinutes)
	}

	func testArrayKey() {
		let key = Defaults.Key<[FixtureCodableEnum]>("independentCodableArrayKey", default: [.tenMinutes])
		XCTAssertEqual(Defaults[key][0], .tenMinutes)
		Defaults[key][0] = .halfHour
		XCTAssertEqual(Defaults[key][0], .halfHour)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[FixtureCodableEnum]?>("independentCodableArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [.halfHour]
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[FixtureCodableEnum]]>("independentCodableNestedArrayKey", default: [[.tenMinutes]])
		XCTAssertEqual(Defaults[key][0][0], .tenMinutes)
		Defaults[key].append([.halfHour])
		Defaults[key][0].append(.oneHour)
		XCTAssertEqual(Defaults[key][1][0], .halfHour)
		XCTAssertEqual(Defaults[key][0][1], .oneHour)
	}

	func testCodableToNonCodable() {
		let codableKeyName = "independentCodableToNonCodableKey1"
		let codableKey = Defaults.Key<FixtureCodableEnum>(codableKeyName, default: .tenMinutes)
		guard let json_string = UserDefaults.standard.object(forKey: codableKeyName) as? String else {
			XCTFail()
			return
		}
		// Drop double quotes which wrapping the json_string
		let serializable = String(String(json_string.dropFirst()).dropLast())
		guard let fixtureEnum = FixtureEnum.bridge.deserialize(serializable) else {
			XCTFail()
			return
		}
		let keyName = "independentCodableToNonCodableKey2"
		let key = Defaults.Key<FixtureEnum>(keyName, default: fixtureEnum)
		XCTAssertEqual(Defaults[codableKey].rawValue, Defaults[key].rawValue)
	}
}
