import Defaults
import Foundation
import XCTest

struct TimeZone: Defaults.Serializable {
	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}

struct CodableTimeZone: Codable {
	let id: String
	let name: String

	func toTimeZone() -> TimeZone {
		TimeZone(id: self.id, name: self.name)
	}
}

struct TimeZoneBridge: Defaults.Bridge {
	typealias Value = Any
	typealias Serializable = Any

	func serialize(_ value: Any?) -> Any? {
		guard let value = value as? TimeZone else {
			return nil
		}

		return ["id": value.id, "name": value.name]
	}

	func deserialize(_ object: Any?) -> Any? {
		// `object` should be a dictionary which `Key` is String and `Value` is Serializable,
		// When it is String, that means we need to do some migration.
		if object is String {
			guard
				let jsonString = object as? String,
				let jsonData = jsonString.data(using: .utf8)
			else {
				return nil
			}
			
			// check json string is valid brutally
			if let instance = try? JSONDecoder().decode(CodableTimeZone.self, from: jsonData) {
				return instance.toTimeZone()
			} else if let array = try? JSONDecoder().decode([CodableTimeZone].self, from: jsonData) {
				return array.map { $0.toTimeZone() }
			} else if let dictionary = try? JSONDecoder().decode([String: CodableTimeZone].self, from: jsonData) {
				return dictionary.reduce(into: [String: TimeZone]()) { memo, tuple in
					memo[tuple.key] = tuple.value.toTimeZone()
				}
			}
			return nil
		}

		guard
			let dictionary = object as? [String: String],
			let id = dictionary["id"],
			let name = dictionary["name"]
		else {
			return nil
		}

		return TimeZone(id: id, name: name)
	}
}

final class DefaultsMigrationTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testArrayToNativeArray() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "codableArrayToNativeArrayKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String]?>(keyName)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
	}

	func testCodableToNativeType() {
		let text = "{\"id\":\"0\", \"name\": \"Asia/Taipei\"}"
		let keyName = "codableCodableToNativeType"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<TimeZone?>(keyName)
		XCTAssertEqual(Defaults[key]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.name = newName
		XCTAssertEqual(Defaults[key]?.name, newName)
	}

	func testArrayAndCodableElementToNativeArray() {
		let text = "[{\"id\":\"0\", \"name\": \"Asia/Taipei\"}]"
		let keyName = "codableArrayAndCodableElementToNativeArray"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[TimeZone]?>(keyName)
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[0].name = newName
		XCTAssertEqual(Defaults[key]?[0].name, newName)
	}

	func testDictionaryToNativelyDictionary() {
		let text = "{\"Hank\":\"Chen\"}"
		let keyName = "codableDictionaryToNativelyDictionary"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: String]?>(keyName)
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}

	func testDictionaryAndCodableValueToNativeDictionary() {
		let text = "{\"0\": {\"id\":\"0\", \"name\": \"Asia/Taipei\"} }"
		let keyName = "codableArrayAndCodableElementToNativeArray"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: TimeZone]?>(keyName)
		XCTAssertEqual(Defaults[key]?["0"]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?["0"]?.name = newName
		XCTAssertEqual(Defaults[key]?["0"]?.name, newName)
	}
}
