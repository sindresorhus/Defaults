import Foundation
import Combine
import XCTest
import Defaults

struct Unicorn: Codable, Defaults.Serializable {
	var isUnicorn: Bool
}

let fixtureCodable = Unicorn(isUnicorn: true)

extension Defaults.Keys {
	static let codable = Key<Unicorn>("codable", default: fixtureCodable)
	static let array_codable = Key<[Unicorn]>("codable", default: [fixtureCodable])
	static let dictionary_codable = Key<[String: Unicorn]>("codable", default: ["0": fixtureCodable])
}

final class DefaultsCodableTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Unicorn>("independentCodableKey", default: fixtureCodable)
		XCTAssertTrue(Defaults[key].isUnicorn)
		Defaults[key].isUnicorn = false
		XCTAssertFalse(Defaults[key].isUnicorn)
	}

	func testOptionalKey() {
		let key = Defaults.Key<Unicorn?>("independentCodableOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = Unicorn(isUnicorn: true)
		XCTAssertTrue(Defaults[key]?.isUnicorn ?? false)
	}

	func testArrayKey() {
		let key = Defaults.Key<[Unicorn]>("independentCodableArrayKey", default: [fixtureCodable])
		XCTAssertTrue(Defaults[key][0].isUnicorn)
		Defaults[key].append(Unicorn(isUnicorn: false))
		XCTAssertTrue(Defaults[key][0].isUnicorn)
		XCTAssertFalse(Defaults[key][1].isUnicorn)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[Unicorn]?>("independentCodableArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [fixtureCodable]
		Defaults[key]?.append(Unicorn(isUnicorn: false))
		XCTAssertTrue(Defaults[key]?[0].isUnicorn ?? false)
		XCTAssertFalse(Defaults[key]?[1].isUnicorn ?? false)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Unicorn]]>("independentCodableNestedArrayKey", default: [[fixtureCodable]])
		XCTAssertTrue(Defaults[key][0][0].isUnicorn)
		Defaults[key].append([fixtureCodable])
		Defaults[key][0].append(Unicorn(isUnicorn: false))
		XCTAssertTrue(Defaults[key][0][0].isUnicorn)
		XCTAssertTrue(Defaults[key][1][0].isUnicorn)
		XCTAssertFalse(Defaults[key][0][1].isUnicorn)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Unicorn]]>("independentCodableArrayDictionaryKey", default: [["0":fixtureCodable]])
		XCTAssertTrue(Defaults[key][0]["0"]?.isUnicorn ?? false)
		Defaults[key].append(["0": fixtureCodable])
		Defaults[key][0]["1"] = Unicorn(isUnicorn: false)
		XCTAssertTrue(Defaults[key][0]["0"]?.isUnicorn ?? false)
		XCTAssertTrue(Defaults[key][1]["0"]?.isUnicorn ?? false)
		XCTAssertFalse(Defaults[key][0]["1"]?.isUnicorn ?? true)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Unicorn]>("independentCodableDictionaryKey", default: ["0":fixtureCodable])
		XCTAssertTrue(Defaults[key]["0"]?.isUnicorn ?? false)
		Defaults[key]["1"] = Unicorn(isUnicorn: false)
		XCTAssertTrue(Defaults[key]["0"]?.isUnicorn ?? false)
		XCTAssertFalse(Defaults[key]["1"]?.isUnicorn ?? true)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Unicorn]?>("independentCodableDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": fixtureCodable]
		Defaults[key]?["1"] = Unicorn(isUnicorn: false)
		XCTAssertTrue(Defaults[key]?["0"]?.isUnicorn ?? false)
		XCTAssertFalse(Defaults[key]?["1"]?.isUnicorn ?? true)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Unicorn]]>("independentCodableDictionaryArrayKey", default: ["0": [fixtureCodable]])
		XCTAssertTrue(Defaults[key]["0"]?[0].isUnicorn ?? false)
		Defaults[key]["1"] = [fixtureCodable]
		Defaults[key]["0"]?.append(Unicorn(isUnicorn: false))
		XCTAssertTrue(Defaults[key]["1"]?[0].isUnicorn ?? false)
		XCTAssertFalse(Defaults[key]["0"]?[1].isUnicorn ?? true)
	}

	func testType() {
		XCTAssertTrue(Defaults[.codable].isUnicorn)
		Defaults[.codable] = Unicorn(isUnicorn: false)
		XCTAssertFalse(Defaults[.codable].isUnicorn)
	}

	func testArrayType() {
		XCTAssertTrue(Defaults[.array_codable][0].isUnicorn)
		Defaults[.array_codable][0] = Unicorn(isUnicorn: false)
		XCTAssertFalse(Defaults[.array_codable][0].isUnicorn)
	}

	func testDictionaryType() {
		XCTAssertTrue(Defaults[.dictionary_codable]["0"]?.isUnicorn ?? false)
		Defaults[.dictionary_codable]["0"] = Unicorn(isUnicorn: false)
		XCTAssertFalse(Defaults[.dictionary_codable]["0"]?.isUnicorn ?? true)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Unicorn>("observeCodableKeyCombine", default: fixtureCodable)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue.isUnicorn, $0.newValue.isUnicorn) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(true, false), (false, true)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0)
				XCTAssertEqual(expected.1, tuples[i].1)
			}

			expect.fulfill()
		}

		Defaults[key] = Unicorn(isUnicorn: false)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<Unicorn?>("observeCodableOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue?.isUnicorn, $0.newValue?.isUnicorn) }
			.collect(2)

		let expectedValue: [(Bool?, Bool?)] = [(nil, true), (true, nil)]

		let cancellable = publisher.sink { tuples in
			for (i, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0)
				XCTAssertEqual(expected.1, tuples[i].1)
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureCodable
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[Unicorn]>("observeCodableArrayKeyCombine", default: [fixtureCodable])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(true, false), (false, true)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0[0].isUnicorn)
				XCTAssertEqual(expected.1, tuples[i].1[0].isUnicorn)
			}

			expect.fulfill()
		}

		Defaults[key][0] = Unicorn(isUnicorn: false)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: Unicorn]>("observeCodableDictionaryKeyCombine", default: ["0": fixtureCodable])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(true, false), (false, true)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0["0"]?.isUnicorn)
				XCTAssertEqual(expected.1, tuples[i].1["0"]?.isUnicorn)
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = Unicorn(isUnicorn: false)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Unicorn>("observeCodableKey", default: fixtureCodable)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue.isUnicorn)
			XCTAssertFalse(change.newValue.isUnicorn)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = Unicorn(isUnicorn: false)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<Unicorn?>("observeCodableOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertTrue(change.newValue?.isUnicorn ?? false)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureCodable
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[Unicorn]>("observeCodableArrayKey", default: [fixtureCodable])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue[0].isUnicorn)
			XCTAssertFalse(change.newValue[0].isUnicorn)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][0] = Unicorn(isUnicorn: false)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: Unicorn]>("observeCodableDictionaryKey", default: ["0": fixtureCodable])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertTrue(change.oldValue["0"]?.isUnicorn ?? false)
			XCTAssertFalse(change.newValue["0"]?.isUnicorn ?? true)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["0"] = Unicorn(isUnicorn: false)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
