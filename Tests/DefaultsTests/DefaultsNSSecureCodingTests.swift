import Foundation
import CoreData
import Testing
import Defaults

private let suite_ = createSuite()

@objc(ExamplePersistentHistory)
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

	override class var supportsSecureCoding: Bool { true } // swiftlint:disable:this non_overridable_class_declaration
}

// NSSecureCoding
private let persistentHistoryValue = ExamplePersistentHistory(value: "ExampleToken")

extension Defaults.Keys {
	fileprivate static let persistentHistory = Key<ExamplePersistentHistory>("persistentHistory", default: persistentHistoryValue, suite: suite_)
	fileprivate static let persistentHistoryArray = Key<[ExamplePersistentHistory]>("array_persistentHistory", default: [persistentHistoryValue], suite: suite_)
	fileprivate static let persistentHistoryDictionary = Key<[String: ExamplePersistentHistory]>("dictionary_persistentHistory", default: ["0": persistentHistoryValue], suite: suite_)
}

@Suite(.serialized)
final class DefaultsNSSecureCodingTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<ExamplePersistentHistory>("independentNSSecureCodingKey", default: persistentHistoryValue, suite: suite_)
		#expect(Defaults[key].value == persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[key] = newPersistentHistory
		#expect(Defaults[key].value == newPersistentHistory.value)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<ExamplePersistentHistory?>("independentNSSecureCodingOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = persistentHistoryValue
		#expect(Defaults[key]?.value == persistentHistoryValue.value)
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[key] = newPersistentHistory
		#expect(Defaults[key]?.value == newPersistentHistory.value)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[ExamplePersistentHistory]>("independentNSSecureCodingArrayKey", default: [persistentHistoryValue], suite: suite_)
		#expect(Defaults[key][0].value == persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key].append(newPersistentHistory1)
		#expect(Defaults[key][1].value == newPersistentHistory1.value)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key][1] = newPersistentHistory2
		#expect(Defaults[key][1].value == newPersistentHistory2.value)
		#expect(Defaults[key][0].value == persistentHistoryValue.value)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[ExamplePersistentHistory]?>("independentNSSecureCodingArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [persistentHistoryValue]
		#expect(Defaults[key]?[0].value == persistentHistoryValue.value)
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[ExamplePersistentHistory]]>("independentNSSecureCodingNestedArrayKey", default: [[persistentHistoryValue]], suite: suite_)
		#expect(Defaults[key][0][0].value == persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key][0].append(newPersistentHistory1)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key].append([newPersistentHistory2])
		#expect(Defaults[key][0][1].value == newPersistentHistory1.value)
		#expect(Defaults[key][1][0].value == newPersistentHistory2.value)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: ExamplePersistentHistory]]>("independentNSSecureCodingArrayDictionaryKey", default: [["0": persistentHistoryValue]], suite: suite_)
		#expect(Defaults[key][0]["0"]?.value == persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key][0]["1"] = newPersistentHistory1
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key].append(["0": newPersistentHistory2])
		#expect(Defaults[key][0]["1"]?.value == newPersistentHistory1.value)
		#expect(Defaults[key][1]["0"]?.value == newPersistentHistory2.value)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]>("independentNSSecureCodingDictionaryKey", default: ["0": persistentHistoryValue], suite: suite_)
		#expect(Defaults[key]["0"]?.value == persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key]["1"] = newPersistentHistory1
		#expect(Defaults[key]["1"]?.value == newPersistentHistory1.value)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key]["1"] = newPersistentHistory2
		#expect(Defaults[key]["1"]?.value == newPersistentHistory2.value)
		#expect(Defaults[key]["0"]?.value == persistentHistoryValue.value)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: ExamplePersistentHistory]?>("independentNSSecureCodingDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": persistentHistoryValue]
		#expect(Defaults[key]?["0"]?.value == persistentHistoryValue.value)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [ExamplePersistentHistory]]>("independentNSSecureCodingDictionaryArrayKey", default: ["0": [persistentHistoryValue]], suite: suite_)
		#expect(Defaults[key]["0"]?[0].value == persistentHistoryValue.value)
		let newPersistentHistory1 = ExamplePersistentHistory(value: "NewValue1")
		Defaults[key]["0"]?.append(newPersistentHistory1)
		let newPersistentHistory2 = ExamplePersistentHistory(value: "NewValue2")
		Defaults[key]["1"] = [newPersistentHistory2]
		#expect(Defaults[key]["0"]?[1].value == newPersistentHistory1.value)
		#expect(Defaults[key]["1"]?[0].value == newPersistentHistory2.value)
	}

	@Test
	func testType() {
		#expect(Defaults[.persistentHistory].value == persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistory] = newPersistentHistory
		#expect(Defaults[.persistentHistory].value == newPersistentHistory.value)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.persistentHistoryArray][0].value == persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistoryArray][0] = newPersistentHistory
		#expect(Defaults[.persistentHistoryArray][0].value == newPersistentHistory.value)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.persistentHistoryDictionary]["0"]?.value == persistentHistoryValue.value)
		let newPersistentHistory = ExamplePersistentHistory(value: "NewValue")
		Defaults[.persistentHistoryDictionary]["0"] = newPersistentHistory
		#expect(Defaults[.persistentHistoryDictionary]["0"]?.value == newPersistentHistory.value)
	}
}
