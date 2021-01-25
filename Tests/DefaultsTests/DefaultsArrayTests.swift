import Foundation
import Defaults
import XCTest

private let fixtureArray = ["Hank", "Chen"]

extension Defaults.Keys {
	fileprivate static let array = Key<[String]>("array", default: fixtureArray)
}

final class DefaultsArrayTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<[String]>("independentArrayStringKey", default: fixtureArray)
		XCTAssertEqual(Defaults[key][0], fixtureArray[0])
		let newValue = "John"
		Defaults[key][0] = newValue
		XCTAssertEqual(Defaults[key][0], newValue)
	}

	func testOptionalKey() {
		let key = Defaults.Key<[String]?>("independentArrayOptionalStringKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureArray
		XCTAssertEqual(Defaults[key]?[0], fixtureArray[0])
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
		let newValue = ["John", "Chen"]
		Defaults[key] = newValue
		XCTAssertEqual(Defaults[key]?[0], newValue[0])
	}

	func testNestedKey() {
		let defaultValue = ["Hank", "Chen"]
		let key = Defaults.Key<[[String]]>("independentArrayNestedKey", default: [defaultValue])
		XCTAssertEqual(Defaults[key][0][0], "Hank")
		let newValue = ["Sindre", "Sorhus"]
		Defaults[key][0] = newValue
		Defaults[key].append(defaultValue)
		XCTAssertEqual(Defaults[key][0][0], newValue[0])
		XCTAssertEqual(Defaults[key][0][1], newValue[1])
		XCTAssertEqual(Defaults[key][1][0], defaultValue[0])
		XCTAssertEqual(Defaults[key][1][1], defaultValue[1])
	}

	func testDictionaryKey() {
		let defaultValue = ["0": "HankChen"]
		let key = Defaults.Key<[[String: String]]>("independentArrayDictionaryKey", default: [defaultValue])
		XCTAssertEqual(Defaults[key][0]["0"], defaultValue["0"])
		let newValue = ["0": "SindreSorhus"]
		Defaults[key][0] = newValue
		Defaults[key].append(defaultValue)
		XCTAssertEqual(Defaults[key][0]["0"], newValue["0"])
		XCTAssertEqual(Defaults[key][1]["0"], defaultValue["0"])
	}

	func testType() {
		XCTAssertEqual(Defaults[.array][0], fixtureArray[0])
		let newName = "Hank121314"
		Defaults[.array][0] = newName
		XCTAssertEqual(Defaults[.array][0], newName)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<[String]>("observeArrayKeyCombine", default: fixtureArray)
		let newName = "Chen"
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureArray[0], newName), (newName, fixtureArray[0])].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
			}

			expect.fulfill()
		}

		Defaults[key][0] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<[String]?>("observeArrayOptionalKeyCombine")
		let newName = ["Chen"]
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		// swiftlint:disable discouraged_optional_collection
		let expectedValues: [([String]?, [String]?)] = [(nil, fixtureArray), (fixtureArray, newName), (newName, nil)]

		let cancellable = publisher.sink { actualValues in
			for (expected, actual) in zip(expectedValues, actualValues) {
				XCTAssertEqual(expected.0, actual.0)
				XCTAssertEqual(expected.1, actual.1)
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureArray
		Defaults[key] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<[String]>("observeArrayKey", default: fixtureArray)
		let newName = "John"
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, fixtureArray)
			XCTAssertEqual(change.newValue, [fixtureArray[0], newName])
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][1] = newName
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<[String]?>("observeArrayOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue!, fixtureArray)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureArray
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testCodableArrayToNativeArray() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "codableArrayToNativeArrayKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String]?>(keyName)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
	}
}
