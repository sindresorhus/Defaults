import Foundation
import Defaults
import XCTest

private enum FixtureCodableEnum: String, Codable, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	fileprivate static let codableEnum = Key<FixtureCodableEnum>("codable_enum", default: .oneHour)
	fileprivate static let codableEnumArray = Key<[FixtureCodableEnum]>("codable_enum", default: [.oneHour])
	fileprivate static let codableEnumDictionary = Key<[String: FixtureCodableEnum]>("codable_enum", default: ["0": .oneHour])
}

final class DefaultsCodableEnumTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<FixtureCodableEnum>("independentCodableEnumKey", default: .tenMinutes)
		XCTAssertEqual(Defaults[key], .tenMinutes)
		Defaults[key] = .halfHour
		XCTAssertEqual(Defaults[key], .halfHour)
	}

	func testOptionalKey() {
		let key = Defaults.Key<FixtureCodableEnum?>("independentCodableEnumOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = .tenMinutes
		XCTAssertEqual(Defaults[key], .tenMinutes)
	}

	func testArrayKey() {
		let key = Defaults.Key<[FixtureCodableEnum]>("independentCodableEnumArrayKey", default: [.tenMinutes])
		XCTAssertEqual(Defaults[key][0], .tenMinutes)
		Defaults[key][0] = .halfHour
		XCTAssertEqual(Defaults[key][0], .halfHour)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[FixtureCodableEnum]?>("independentCodableEnumArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [.halfHour]
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[FixtureCodableEnum]]>("independentCodableEnumNestedArrayKey", default: [[.tenMinutes]])
		XCTAssertEqual(Defaults[key][0][0], .tenMinutes)
		Defaults[key].append([.halfHour])
		Defaults[key][0].append(.oneHour)
		XCTAssertEqual(Defaults[key][1][0], .halfHour)
		XCTAssertEqual(Defaults[key][0][1], .oneHour)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: FixtureCodableEnum]]>("independentCodableEnumArrayDictionaryKey", default: [["0": .tenMinutes]])
		XCTAssertEqual(Defaults[key][0]["0"], .tenMinutes)
		Defaults[key][0]["1"] = .halfHour
		Defaults[key].append(["0": .oneHour])
		XCTAssertEqual(Defaults[key][0]["1"], .halfHour)
		XCTAssertEqual(Defaults[key][1]["0"], .oneHour)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: FixtureCodableEnum]>("independentCodableEnumDictionaryKey", default: ["0": .tenMinutes])
		XCTAssertEqual(Defaults[key]["0"], .tenMinutes)
		Defaults[key]["1"] = .halfHour
		Defaults[key]["0"] = .oneHour
		XCTAssertEqual(Defaults[key]["0"], .oneHour)
		XCTAssertEqual(Defaults[key]["1"], .halfHour)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: FixtureCodableEnum]?>("independentCodableEnumDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": .tenMinutes]
		Defaults[key]?["1"] = .halfHour
		XCTAssertEqual(Defaults[key]?["0"], .tenMinutes)
		XCTAssertEqual(Defaults[key]?["1"], .halfHour)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [FixtureCodableEnum]]>("independentCodableEnumDictionaryArrayKey", default: ["0": [.tenMinutes]])
		XCTAssertEqual(Defaults[key]["0"]?[0], .tenMinutes)
		Defaults[key]["0"]?.append(.halfHour)
		Defaults[key]["1"] = [.oneHour]
		XCTAssertEqual(Defaults[key]["0"]?[0], .tenMinutes)
		XCTAssertEqual(Defaults[key]["0"]?[1], .halfHour)
		XCTAssertEqual(Defaults[key]["1"]?[0], .oneHour)
	}

	func testType() {
		XCTAssertEqual(Defaults[.codableEnum], .oneHour)
		Defaults[.codableEnum] = .tenMinutes
		XCTAssertEqual(Defaults[.codableEnum], .tenMinutes)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.codableEnumArray][0], .oneHour)
		Defaults[.codableEnumArray].append(.halfHour)
		XCTAssertEqual(Defaults[.codableEnumArray][0], .oneHour)
		XCTAssertEqual(Defaults[.codableEnumArray][1], .halfHour)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.codableEnumDictionary]["0"], .oneHour)
		Defaults[.codableEnumDictionary]["1"] = .halfHour
		XCTAssertEqual(Defaults[.codableEnumDictionary]["0"], .oneHour)
		XCTAssertEqual(Defaults[.codableEnumDictionary]["1"], .halfHour)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<FixtureCodableEnum>("observeCodableEnumKeyCombine", default: .tenMinutes)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(FixtureCodableEnum, FixtureCodableEnum)] = [(.tenMinutes, .oneHour), (.oneHour, .tenMinutes)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = .oneHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<FixtureCodableEnum?>("observeCodableEnumOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(FixtureCodableEnum?, FixtureCodableEnum?)] = [(nil, .tenMinutes), (.tenMinutes, .halfHour), (.halfHour, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = .tenMinutes
		Defaults[key] = .halfHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[FixtureCodableEnum]>("observeCodableEnumArrayKeyCombine", default: [.tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(FixtureCodableEnum?, FixtureCodableEnum?)] = [(.tenMinutes, .halfHour), (.halfHour, .tenMinutes)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
			}

			expect.fulfill()
		}

		Defaults[key][0] = .halfHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: FixtureCodableEnum]>("observeCodableEnumDictionaryKeyCombine", default: ["0": .tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(FixtureCodableEnum?, FixtureCodableEnum?)] = [(.tenMinutes, .halfHour), (.halfHour, .tenMinutes)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"])
				XCTAssertEqual(expected.1, tuples[index].1["0"])
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = .halfHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<FixtureCodableEnum>("observeCodableEnumKey", default: .tenMinutes)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, .tenMinutes)
			XCTAssertEqual(change.newValue, .halfHour)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .halfHour
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<FixtureCodableEnum?>("observeCodableEnumOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue, .halfHour)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .halfHour
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[FixtureCodableEnum]>("observeCodableEnumArrayKey", default: [.tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0], .tenMinutes)
			XCTAssertEqual(change.newValue[1], .halfHour)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].append(.halfHour)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: FixtureCodableEnum]>("observeCodableEnumDictionaryKey", default: ["0": .tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"], .tenMinutes)
			XCTAssertEqual(change.newValue["1"], .halfHour)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["1"] = .halfHour
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
