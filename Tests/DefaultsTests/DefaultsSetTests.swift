import Foundation
import Defaults
import XCTest

private let fixtureSet = Set(1...5)

extension Defaults.Keys {
	fileprivate static let set = Key<Set<Int>>("setInt", default: fixtureSet)
}

final class DefaultsSetTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Set<Int>>("independentSetKey", default: fixtureSet)
		XCTAssertEqual(Defaults[key].count, fixtureSet.count)
		Defaults[key].insert(6)
		XCTAssertEqual(Defaults[key], Set(1...6))
	}

	func testOptionalKey() {
		let key = Defaults.Key<Set<Int>?>("independentSetOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureSet
		XCTAssertEqual(Defaults[key]?.count, fixtureSet.count)
		Defaults[key]?.insert(6)
		XCTAssertEqual(Defaults[key], Set(1...6))
	}

	func testArrayKey() {
		let key = Defaults.Key<[Set<Int>]>("independentSetArrayKey", default: [fixtureSet])
		XCTAssertEqual(Defaults[key][0].count, fixtureSet.count)
		Defaults[key][0].insert(6)
		XCTAssertEqual(Defaults[key][0], Set(1...6))
		Defaults[key].append(Set(1...4))
		XCTAssertEqual(Defaults[key][1], Set(1...4))
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Set<Int>]>("independentSetArrayKey", default: ["0": fixtureSet])
		XCTAssertEqual(Defaults[key]["0"]?.count, fixtureSet.count)
		Defaults[key]["0"]?.insert(6)
		XCTAssertEqual(Defaults[key]["0"], Set(1...6))
		Defaults[key]["1"] = Set(1...4)
		XCTAssertEqual(Defaults[key]["1"], Set(1...4))
	}

	func testCodableArrayToNativeSet() {
		let keyName = "codableArrayToNativeSetKey"
		let text = "[\"a\",\"b\",\"c\"]"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<Set<String>>(keyName, default: [])
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c"]))
		Defaults[key].insert("d")
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c", "d"]))
		Defaults.reset(key)
		XCTAssertEqual(Defaults[key], [])
	}

	func testCodableArrayToNativeOptionalSet() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "codableArrayToNativeOptionalSetKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<Set<String>?>(keyName)
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c"]))
		Defaults[key]?.insert("d")
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c", "d"]))
		Defaults.reset(key)
		XCTAssertNil(Defaults[key])
	}
}
