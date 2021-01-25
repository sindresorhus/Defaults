import Foundation
import CoreData
import Defaults
import XCTest

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
private final class ExamplePersistentHistory: NSPersistentHistoryToken, Defaults.Serializable {
	let value: String

	init(value: String) {
		self.value = value
		super.init()
	}

	required init?(coder: NSCoder) {
		self.value = coder.decodeObject(forKey: "value") as! String
		super.init()
	}

	override func encode(with coder: NSCoder) {
		coder.encode(value, forKey: "value")
	}

	override class var supportsSecureCoding: Bool { true }
}

// NSSecureCoding
@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
private let persistentHistoryValue = ExamplePersistentHistory(value: "ExampleToken")

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
extension Defaults.Keys {
	fileprivate static let persistentHistory = Key<ExamplePersistentHistory>("persistentHistory", default: persistentHistoryValue)
	fileprivate static let persistentHistoryArray = Key<[ExamplePersistentHistory]>("array_persistentHistory", default: [persistentHistoryValue])
	fileprivate static let persistentHistoryDictionary = Key<[String: ExamplePersistentHistory]>("dictionary_persistentHistory", default: ["0": persistentHistoryValue])
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
final class DefaultsNSSecureCodingTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<ExamplePersistentHistory>("independentNSSecureCodingKey", default: persistentHistoryValue)
		XCTAssertEqual(Defaults[key].value, persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[key] = newPersistentHistory
		XCTAssertEqual(Defaults[key].value, newPersistentHistory.value)
	}

	func testOptionalKey() {
		let key = Defaults.Key<ExamplePersistentHistory?>("independentNSSecureCodingOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = persistentHistoryValue
		XCTAssertEqual(Defaults[key]?.value, persistentHistoryValue.value)
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[key] = newPersistentHistory
		XCTAssertEqual(Defaults[key]?.value, newPersistentHistory.value)
	}

	func testArrayKey() {
		let key = Defaults.Key<[ExamplePersistentHistory]>("independentNSSecureCodingArrayKey", default: [persistentHistoryValue])
		XCTAssertEqual(Defaults[key][0].value, persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key].append(newPersistentHistory1)
		XCTAssertEqual(Defaults[key][1].value, newPersistentHistory1.value)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key][1] = newPersistentHistory2
		XCTAssertEqual(Defaults[key][1].value, newPersistentHistory2.value)
		XCTAssertEqual(Defaults[key][0].value, persistentHistoryValue.value)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[ExamplePersistentHistory]?>("independentNSSecureCodingArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [persistentHistoryValue]
		XCTAssertEqual(Defaults[key]?[0].value, persistentHistoryValue.value)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[ExamplePersistentHistory]]>("independentNSSecureCodingNestedArrayKey", default: [[persistentHistoryValue]])
		XCTAssertEqual(Defaults[key][0][0].value, persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key][0].append(newPersistentHistory1)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key].append([newPersistentHistory2])
		XCTAssertEqual(Defaults[key][0][1].value, newPersistentHistory1.value)
		XCTAssertEqual(Defaults[key][1][0].value, newPersistentHistory2.value)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: ExamplePersistentHistory]]>("independentNSSecureCodingArrayDictionaryKey", default: [["0": persistentHistoryValue]])
		XCTAssertEqual(Defaults[key][0]["0"]?.value, persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key][0]["1"] = newPersistentHistory1
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key].append(["0": newPersistentHistory2])
		XCTAssertEqual(Defaults[key][0]["1"]?.value, newPersistentHistory1.value)
		XCTAssertEqual(Defaults[key][1]["0"]?.value, newPersistentHistory2.value)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]>("independentNSSecureCodingDictionaryKey", default: ["0": persistentHistoryValue])
		XCTAssertEqual(Defaults[key]["0"]?.value, persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key]["1"] = newPersistentHistory1
		XCTAssertEqual(Defaults[key]["1"]?.value, newPersistentHistory1.value)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key]["1"] = newPersistentHistory2
		XCTAssertEqual(Defaults[key]["1"]?.value, newPersistentHistory2.value)
		XCTAssertEqual(Defaults[key]["0"]?.value, persistentHistoryValue.value)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]?>("independentNSSecureCodingDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": persistentHistoryValue]
		XCTAssertEqual(Defaults[key]?["0"]?.value, persistentHistoryValue.value)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [ExamplePersistentHistory]]>("independentNSSecureCodingDictionaryArrayKey", default: ["0": [persistentHistoryValue]])
		XCTAssertEqual(Defaults[key]["0"]?[0].value, persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key]["0"]?.append(newPersistentHistory1)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key]["1"] = [newPersistentHistory2]
		XCTAssertEqual(Defaults[key]["0"]?[1].value, newPersistentHistory1.value)
		XCTAssertEqual(Defaults[key]["1"]?[0].value, newPersistentHistory2.value)
	}

	func testType() {
		XCTAssertEqual(Defaults[.persistentHistory].value, persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistory] = newPersistentHistory
		XCTAssertEqual(Defaults[.persistentHistory].value, newPersistentHistory.value)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.persistentHistoryArray][0].value, persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistoryArray][0] = newPersistentHistory
		XCTAssertEqual(Defaults[.persistentHistoryArray][0].value, newPersistentHistory.value)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.persistentHistoryDictionary]["0"]?.value, persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistoryDictionary]["0"] = newPersistentHistory
		XCTAssertEqual(Defaults[.persistentHistoryDictionary]["0"]?.value, newPersistentHistory.value)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<ExamplePersistentHistory>("observeNSSecureCodingKeyCombine", default: persistentHistoryValue)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue.value, $0.newValue.value) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(persistentHistoryValue.value, newPersistentHistory.value), (newPersistentHistory.value, persistentHistoryValue.value)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = newPersistentHistory
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<ExamplePersistentHistory?>("observeNSSecureCodingOptionalKeyCombine")
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue?.value, $0.newValue?.value) }
			.collect(3)

		let expectedValue: [(ExamplePersistentHistory?, ExamplePersistentHistory?)] = [(nil, persistentHistoryValue), (persistentHistoryValue, newPersistentHistory), (newPersistentHistory, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0?.value, tuples[index].0)
				XCTAssertEqual(expected.1?.value, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = persistentHistoryValue
		Defaults[key] = newPersistentHistory
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[ExamplePersistentHistory]>("observeNSSecureCodingArrayKeyCombine", default: [persistentHistoryValue])
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(ExamplePersistentHistory, ExamplePersistentHistory)] = [(persistentHistoryValue, newPersistentHistory), (newPersistentHistory, persistentHistoryValue)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0.value, tuples[index].0[0].value)
				XCTAssertEqual(expected.1.value, tuples[index].1[0].value)
			}

			expect.fulfill()
		}

		Defaults[key][0] = newPersistentHistory
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]>("observeNSSecureCodingDictionaryKeyCombine", default: ["0": persistentHistoryValue])
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(ExamplePersistentHistory, ExamplePersistentHistory)] = [(persistentHistoryValue, newPersistentHistory), (newPersistentHistory, persistentHistoryValue)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0.value, tuples[index].0["0"]?.value)
				XCTAssertEqual(expected.1.value, tuples[index].1["0"]?.value)
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = newPersistentHistory
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveMultipleNSSecureKeysCombine() {
		let key1 = Defaults.Key<ExamplePersistentHistory>("observeMultipleNSSecureCodingKey1", default: ExamplePersistentHistory(value: "TestValue"))
		let key2 = Defaults.Key<ExamplePersistentHistory>("observeMultipleNSSecureCodingKey2", default: ExamplePersistentHistory(value: "TestValue"))
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults.publisher(keys: key1, key2, options: []).collect(2)

		let cancellable = publisher.sink { _ in
			expect.fulfill()
		}

		Defaults[key1] = ExamplePersistentHistory(value: "NewTestValue1")
		Defaults[key2] = ExamplePersistentHistory(value: "NewTestValue2")
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveMultipleNSSecureOptionalKeysCombine() {
		let key1 = Defaults.Key<ExamplePersistentHistory?>("observeMultipleNSSecureCodingOptionalKey1")
		let key2 = Defaults.Key<ExamplePersistentHistory?>("observeMultipleNSSecureCodingOptionalKeyKey2")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults.publisher(keys: key1, key2, options: []).collect(2)

		let cancellable = publisher.sink { _ in
			expect.fulfill()
		}

		Defaults[key1] = ExamplePersistentHistory(value: "NewTestValue1")
		Defaults[key2] = ExamplePersistentHistory(value: "NewTestValue2")
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	func testObserveMultipleNSSecureKeys() {
		let key1 = Defaults.Key<ExamplePersistentHistory>("observeNSSecureCodingKey1", default: ExamplePersistentHistory(value: "TestValue"))
		let key2 = Defaults.Key<ExamplePersistentHistory>("observeNSSecureCodingKey2", default: ExamplePersistentHistory(value: "TestValue"))
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		var counter = 0
		observation = Defaults.observe(keys: key1, key2, options: []) {
			counter += 1
			if counter == 2 {
				expect.fulfill()
			} else if counter > 2 {
				XCTFail()
			}
		}

		Defaults[key1] = ExamplePersistentHistory(value: "NewTestValue1")
		Defaults[key2] = ExamplePersistentHistory(value: "NewTestValue2")
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<ExamplePersistentHistory>("observeNSSecureCodingKey", default: persistentHistoryValue)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue.value, persistentHistoryValue.value)
			XCTAssertEqual(change.newValue.value, newPersistentHistory.value)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = newPersistentHistory
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<ExamplePersistentHistory?>("observeNSSecureCodingOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?.value, persistentHistoryValue.value)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = persistentHistoryValue
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[ExamplePersistentHistory]>("observeNSSecureCodingArrayKey", default: [persistentHistoryValue])
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0].value, persistentHistoryValue.value)
			XCTAssertEqual(change.newValue.map { $0.value }, [persistentHistoryValue, newPersistentHistory].map { $0.value })
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].append(newPersistentHistory)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]>("observeNSSecureCodingDictionaryKey", default: ["0": persistentHistoryValue])
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"]?.value, persistentHistoryValue.value)
			XCTAssertEqual(change.newValue["0"]?.value, persistentHistoryValue.value)
			XCTAssertEqual(change.newValue["1"]?.value, newPersistentHistory.value)

			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["1"] = newPersistentHistory
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
