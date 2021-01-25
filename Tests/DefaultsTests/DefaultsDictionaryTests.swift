import Foundation
import Defaults
import XCTest

private let fixtureDictionary = ["0": "Hank"]

private let fixtureArray = ["Hank", "Chen"]

extension Defaults.Keys {
	fileprivate static let dictionary = Key<[String: String]>("dictionary", default: fixtureDictionary)
}

final class DefaultsDictionaryTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<[String: String]>("independentDictionaryStringKey", default: fixtureDictionary)
		XCTAssertEqual(Defaults[key]["0"], fixtureDictionary["0"])
		let newValue = "John"
		Defaults[key]["0"] = newValue
		XCTAssertEqual(Defaults[key]["0"], newValue)
	}

	func testOptionalKey() {
		let key = Defaults.Key<[String: String]?>("independentDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureDictionary
		XCTAssertEqual(Defaults[key]?["0"], fixtureDictionary["0"])
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
		let newValue = ["0": "Chen"]
		Defaults[key] = newValue
		XCTAssertEqual(Defaults[key]?["0"], newValue["0"])
	}

	func testNestedKey() {
		let key = Defaults.Key<[String: [String: String]]>("independentDictionaryNestedKey", default: ["0": fixtureDictionary])
		XCTAssertEqual(Defaults[key]["0"]?["0"], "Hank")
		let newName = "Chen"
		Defaults[key]["0"]?["0"] = newName
		XCTAssertEqual(Defaults[key]["0"]?["0"], newName)
	}

	func testArrayKey() {
		let key = Defaults.Key<[String: [String]]>("independentDictionaryArrayKey", default: ["0": fixtureArray])
		XCTAssertEqual(Defaults[key]["0"], fixtureArray)
		let newName = "Chen"
		Defaults[key]["0"]?[0] = newName
		XCTAssertEqual(Defaults[key]["0"], [newName, fixtureArray[1]])
	}

	func testType() {
		XCTAssertEqual(Defaults[.dictionary]["0"], fixtureDictionary["0"])
		let newName = "Chen"
		Defaults[.dictionary]["0"] = newName
		XCTAssertEqual(Defaults[.dictionary]["0"], newName)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<[String: String]>("observeDictionaryKeyCombine", default: fixtureDictionary)
		let expect = expectation(description: "Observation closure being called")
		let newName = "John"

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureDictionary["0"]!, newName), (newName, fixtureDictionary["0"]!)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"])
				XCTAssertEqual(expected.1, tuples[index].1["0"])
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<[String: String]?>("observeDictionaryOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")
		let newName = ["0": "John"]
		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		// swiftlint:disable discouraged_optional_collection
		let expectedValues: [([String: String]?, [String: String]?)] = [(nil, fixtureDictionary), (fixtureDictionary, newName), (newName, nil)]

		let cancellable = publisher.sink { actualValues in
			for (expected, actual) in zip(expectedValues, actualValues) {
				XCTAssertEqual(expected.0, actual.0)
				XCTAssertEqual(expected.1, actual.1)
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureDictionary
		Defaults[key] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<[String: String]>("observeDictionaryKey", default: fixtureDictionary)
		let expect = expectation(description: "Observation closure being called")
		let newName = "John"

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, fixtureDictionary)
			XCTAssertEqual(change.newValue["1"], newName)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["1"] = newName
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<[String: String]?>("observeDictionaryOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue!, fixtureDictionary)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureDictionary
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testCodableDictionaryToNativelyDictionary() {
		let text = "{\"Hank\":\"Chen\"}"
		let keyName = "codableDictionaryToNativelyDictionary"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: String]?>(keyName)
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}
}
