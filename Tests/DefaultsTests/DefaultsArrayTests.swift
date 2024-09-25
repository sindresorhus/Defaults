import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private let fixtureArray = ["Hank", "Chen"]

extension Defaults.Keys {
	fileprivate static let array = Key<[String]>("array", default: fixtureArray, suite: suite_)
}

@Suite(.serialized)
final class DefaultsArrayTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<[String]>("independentArrayStringKey", default: fixtureArray, suite: suite_)
		#expect(Defaults[key][0] == fixtureArray[0])
		let newValue = "John"
		Defaults[key][0] = newValue
		#expect(Defaults[key][0] == newValue)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<[String]?>("independentArrayOptionalStringKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = fixtureArray
		#expect(Defaults[key]?[0] == fixtureArray[0])
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
		let newValue = ["John", "Chen"]
		Defaults[key] = newValue
		#expect(Defaults[key]?[0] == newValue[0])
	}

	@Test
	func testNestedKey() {
		let defaultValue = ["Hank", "Chen"]
		let key = Defaults.Key<[[String]]>("independentArrayNestedKey", default: [defaultValue], suite: suite_)
		#expect(Defaults[key][0][0] == "Hank")
		let newValue = ["Sindre", "Sorhus"]
		Defaults[key][0] = newValue
		Defaults[key].append(defaultValue)
		#expect(Defaults[key][0][0] == newValue[0])
		#expect(Defaults[key][0][1] == newValue[1])
		#expect(Defaults[key][1][0] == defaultValue[0])
		#expect(Defaults[key][1][1] == defaultValue[1])
	}

	@Test
	func testDictionaryKey() {
		let defaultValue = ["0": "HankChen"]
		let key = Defaults.Key<[[String: String]]>("independentArrayDictionaryKey", default: [defaultValue], suite: suite_)
		#expect(Defaults[key][0]["0"] == defaultValue["0"])
		let newValue = ["0": "SindreSorhus"]
		Defaults[key][0] = newValue
		Defaults[key].append(defaultValue)
		#expect(Defaults[key][0]["0"] == newValue["0"])
		#expect(Defaults[key][1]["0"] == defaultValue["0"])
	}

	@Test
	func testNestedDictionaryKey() {
		let defaultValue = ["0": [["0": 0]]]
		let key = Defaults.Key<[[String: [[String: Int]]]]>("independentArrayNestedDictionaryKey", default: [defaultValue], suite: suite_)
		#expect(Defaults[key][0]["0"]?[0]["0"] == 0)
		let newValue = 1
		Defaults[key][0]["0"]?[0]["0"] = newValue
		Defaults[key].append(defaultValue)
		#expect(Defaults[key][1]["0"]?[0]["0"] == 0)
		#expect(Defaults[key][0]["0"]?[0]["0"] == newValue)
	}

	@Test
	func testType() {
		#expect(Defaults[.array][0] == fixtureArray[0])
		let newName = "Hank121314"
		Defaults[.array][0] = newName
		#expect(Defaults[.array][0] == newName)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveKeyCombine() async {
		let key = Defaults.Key<[String]>("observeArrayKeyCombine", default: fixtureArray, suite: suite_)
		let newName = "Chen"

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValues = [(fixtureArray[0], newName), (newName, fixtureArray[0])]

		Task {
			try? await Task.sleep(for: .seconds(0.1))
			Defaults[key][0] = newName
			Defaults.reset(key)
		}

		for await tuples in publisher.values {
			for (index, expected) in expectedValues.enumerated() {
				#expect(expected.0 == tuples[index].0[0])
				#expect(expected.1 == tuples[index].1[0])
			}

			break
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveOptionalKeyCombine() async {
		let key = Defaults.Key<[String]?>("observeArrayOptionalKeyCombine", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		let newName = ["Chen"]

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		// swiftlint:disable:next discouraged_optional_collection
		let expectedValues: [([String]?, [String]?)] = [(nil, fixtureArray), (fixtureArray, newName), (newName, nil)]

		Task {
			try? await Task.sleep(for: .seconds(0.1))
			Defaults[key] = fixtureArray
			Defaults[key] = newName
			Defaults.reset(key)
		}

		for await actualValues in publisher.values {
			for (expected, actual) in zip(expectedValues, actualValues) {
				#expect(expected.0 == actual.0)
				#expect(expected.1 == actual.1)
			}

			break
		}
	}
}
