import Foundation
import Defaults
import XCTest

private enum FixtureEnum: String, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	fileprivate static let `enum` = Key<FixtureEnum>("enum", default: .tenMinutes)
	fileprivate static let enumArray = Key<[FixtureEnum]>("array_enum", default: [.tenMinutes])
	fileprivate static let enumDictionary = Key<[String: FixtureEnum]>("dictionary_enum", default: ["0": .tenMinutes])
}

final class DefaultsEnumTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<FixtureEnum>("independentEnumKey", default: .tenMinutes)
		XCTAssertEqual(Defaults[key], .tenMinutes)
		Defaults[key] = .halfHour
		XCTAssertEqual(Defaults[key], .halfHour)
	}

	func testOptionalKey() {
		let key = Defaults.Key<FixtureEnum?>("independentEnumOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = .tenMinutes
		XCTAssertEqual(Defaults[key], .tenMinutes)
	}

	func testArrayKey() {
		let key = Defaults.Key<[FixtureEnum]>("independentEnumArrayKey", default: [.tenMinutes])
		XCTAssertEqual(Defaults[key][0], .tenMinutes)
		Defaults[key].append(.halfHour)
		XCTAssertEqual(Defaults[key][0], .tenMinutes)
		XCTAssertEqual(Defaults[key][1], .halfHour)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[FixtureEnum]?>("independentEnumArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [.tenMinutes]
		Defaults[key]?.append(.halfHour)
		XCTAssertEqual(Defaults[key]?[0], .tenMinutes)
		XCTAssertEqual(Defaults[key]?[1], .halfHour)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[FixtureEnum]]>("independentEnumNestedArrayKey", default: [[.tenMinutes]])
		XCTAssertEqual(Defaults[key][0][0], .tenMinutes)
		Defaults[key][0].append(.halfHour)
		Defaults[key].append([.oneHour])
		XCTAssertEqual(Defaults[key][0][1], .halfHour)
		XCTAssertEqual(Defaults[key][1][0], .oneHour)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: FixtureEnum]]>("independentEnumArrayDictionaryKey", default: [["0": .tenMinutes]])
		XCTAssertEqual(Defaults[key][0]["0"], .tenMinutes)
		Defaults[key][0]["1"] = .halfHour
		Defaults[key].append(["0": .oneHour])
		XCTAssertEqual(Defaults[key][0]["1"], .halfHour)
		XCTAssertEqual(Defaults[key][1]["0"], .oneHour)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: FixtureEnum]>("independentEnumDictionaryKey", default: ["0": .tenMinutes])
		XCTAssertEqual(Defaults[key]["0"], .tenMinutes)
		Defaults[key]["1"] = .halfHour
		XCTAssertEqual(Defaults[key]["0"], .tenMinutes)
		XCTAssertEqual(Defaults[key]["1"], .halfHour)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: FixtureEnum]?>("independentEnumDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": .tenMinutes]
		XCTAssertEqual(Defaults[key]?["0"], .tenMinutes)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [FixtureEnum]]>("independentEnumDictionaryKey", default: ["0": [.tenMinutes]])
		XCTAssertEqual(Defaults[key]["0"]?[0], .tenMinutes)
		Defaults[key]["0"]?.append(.halfHour)
		Defaults[key]["1"] = [.oneHour]
		XCTAssertEqual(Defaults[key]["0"]?[1], .halfHour)
		XCTAssertEqual(Defaults[key]["1"]?[0], .oneHour)
	}

	func testType() {
		XCTAssertEqual(Defaults[.enum], .tenMinutes)
		Defaults[.enum] = .halfHour
		XCTAssertEqual(Defaults[.enum], .halfHour)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.enumArray][0], .tenMinutes)
		Defaults[.enumArray][0] = .oneHour
		XCTAssertEqual(Defaults[.enumArray][0], .oneHour)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.enumDictionary]["0"], .tenMinutes)
		Defaults[.enumDictionary]["0"] = .halfHour
		XCTAssertEqual(Defaults[.enumDictionary]["0"], .halfHour)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<FixtureEnum>("observeEnumKeyCombine", default: .tenMinutes)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(FixtureEnum, FixtureEnum)] = [(.tenMinutes, .halfHour), (.halfHour, .oneHour), (.oneHour, .tenMinutes)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = .tenMinutes
		Defaults[key] = .halfHour
		Defaults[key] = .oneHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<FixtureEnum?>("observeEnumOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(4)

		let expectedValue: [(FixtureEnum?, FixtureEnum?)] = [(nil, .tenMinutes), (.tenMinutes, .halfHour), (.halfHour, .oneHour), (.oneHour, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = .tenMinutes
		Defaults[key] = .halfHour
		Defaults[key] = .oneHour
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[FixtureEnum]>("observeEnumArrayKeyCombine", default: [.tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(FixtureEnum, FixtureEnum)] = [(.tenMinutes, .halfHour), (.halfHour, .oneHour)]


		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
			}

			expect.fulfill()
		}

		Defaults[key][0] = .halfHour
		Defaults[key][0] = .oneHour
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: FixtureEnum]>("observeEnumDictionaryKeyCombine", default: ["0": .tenMinutes])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(FixtureEnum, FixtureEnum)] = [(.tenMinutes, .halfHour), (.halfHour, .oneHour)]


		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"])
				XCTAssertEqual(expected.1, tuples[index].1["0"])
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = .halfHour
		Defaults[key]["0"] = .oneHour
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<FixtureEnum>("observeEnumKey", default: .tenMinutes)
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
		let key = Defaults.Key<FixtureEnum?>("observeEnumOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue, .tenMinutes)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .tenMinutes
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[FixtureEnum]>("observeEnumArrayKey", default: [.tenMinutes])
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
		let key = Defaults.Key<[String: FixtureEnum]>("observeEnumDictionaryKey", default: ["0": .tenMinutes])
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
