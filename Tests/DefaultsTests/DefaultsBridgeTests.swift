import Foundation
import Testing
@testable import Defaults

private let suite_ = UserDefaults(suiteName: UUID().uuidString)!

// Test structs for bridge testing
private struct CodableStruct: Codable, Defaults.Serializable {
	let name: String
	let value: Int
}

private struct CodableStructWithCustomBridge: Defaults.Serializable {
	let data: String

	static let bridge = CustomCodableStructBridge()
}

private struct CustomCodableStructBridge: Defaults.Bridge {
	typealias Value = CodableStructWithCustomBridge
	typealias Serializable = String

	func serialize(_ value: CodableStructWithCustomBridge?) -> String? {
		value?.data
	}

	func deserialize(_ object: String?) -> CodableStructWithCustomBridge? {
		guard let object else {
			return nil
		}

		return CodableStructWithCustomBridge(data: object)
	}
}

private enum TestEnum: String, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
	case first = "first_value"
	case second = "second_value"
}

private enum TestEnumCodable: String, Codable, Defaults.Serializable {
	case alpha = "alpha_value"
	case beta = "beta_value"
}

private enum Category: String, CodingKeyRepresentable {
	case electronics
	case books
	case clothing
}

private enum Priority: Int, CodingKeyRepresentable {
	case low = 1
	case medium = 5
	case high = 10
}

// RawRepresentable types automatically get CodingKeyRepresentable conformance
// via stdlib's default implementation when RawValue is String or Int
private struct BundleIdentifier: RawRepresentable, Hashable, Codable, CodingKeyRepresentable {
	let rawValue: String

	init(rawValue: String) {
		self.rawValue = rawValue
	}

	init(_ value: String) {
		self.init(rawValue: value)
	}
}

private struct UserID: RawRepresentable, Hashable, Codable, CodingKeyRepresentable {
	let rawValue: Int

	init(rawValue: Int) {
		self.rawValue = rawValue
	}
}

@Suite(.serialized)
final class DefaultsBridgeTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testCodableBridge() {
		let key = Defaults.Key<CodableStruct>("codableStruct", default: CodableStruct(name: "default", value: 0), suite: suite_)

		// Test default value
		#expect(Defaults[key].name == "default")
		#expect(Defaults[key].value == 0)

		// Test setting and getting
		let newValue = CodableStruct(name: "test", value: 42)
		Defaults[key] = newValue

		#expect(Defaults[key].name == "test")
		#expect(Defaults[key].value == 42)

		// Test persistence across instances
		let anotherKey = Defaults.Key<CodableStruct>("codableStruct", default: CodableStruct(name: "fallback", value: -1), suite: suite_)
		#expect(Defaults[anotherKey].name == "test")
		#expect(Defaults[anotherKey].value == 42)
	}

	@Test
	func testCustomBridge() {
		let key = Defaults.Key<CodableStructWithCustomBridge>("customBridge", default: CodableStructWithCustomBridge(data: "default"), suite: suite_)

		// Test default value
		#expect(Defaults[key].data == "default")

		// Test setting and getting
		let newValue = CodableStructWithCustomBridge(data: "custom_test")
		Defaults[key] = newValue

		#expect(Defaults[key].data == "custom_test")

		// Verify the bridge is actually used by checking the stored value
		let storedValue = suite_.string(forKey: "customBridge")
		#expect(storedValue == "custom_test")
	}

	@Test
	func testRawRepresentablePreference() {
		let key = Defaults.Key<TestEnum>("enumPreferRaw", default: .first, suite: suite_)

		// Test default value
		#expect(Defaults[key] == .first)

		// Test setting and getting
		Defaults[key] = .second
		#expect(Defaults[key] == .second)

		// Verify raw value is stored (not JSON)
		let storedValue = suite_.string(forKey: "enumPreferRaw")
		#expect(storedValue == "second_value")
	}

	@Test
	func testCodableEnum() {
		let key = Defaults.Key<TestEnumCodable>("enumCodable", default: .alpha, suite: suite_)

		// Test default value
		#expect(Defaults[key] == .alpha)

		// Test setting and getting
		Defaults[key] = .beta
		#expect(Defaults[key] == .beta)

		// For Codable enums without PreferRawRepresentable, it should use Codable bridge
		// This means it would be stored as JSON
		let storedValue = suite_.object(forKey: "enumCodable")
		#expect(storedValue != nil)
	}

	@Test
	func testOptionalBridge() {
		let key = Defaults.Key<CodableStruct?>("optionalCodable", suite: suite_)

		// Test nil default
		#expect(Defaults[key] == nil)

		// Test setting a value
		let value = CodableStruct(name: "optional", value: 99)
		Defaults[key] = value

		#expect(Defaults[key]?.name == "optional")
		#expect(Defaults[key]?.value == 99)

		// Test setting back to nil
		Defaults[key] = nil
		#expect(Defaults[key] == nil)

		// Verify nil removes the key
		#expect(suite_.object(forKey: "optionalCodable") == nil)
	}

	@Test
	func testArrayBridge() {
		let key = Defaults.Key<[CodableStruct]>("arrayOfStructs", default: [], suite: suite_)

		// Test empty default
		#expect(Defaults[key].isEmpty)

		// Test setting array
		let structs = [
			CodableStruct(name: "first", value: 1),
			CodableStruct(name: "second", value: 2)
		]
		Defaults[key] = structs

		#expect(Defaults[key].count == 2)
		#expect(Defaults[key][0].name == "first")
		#expect(Defaults[key][1].value == 2)

		// Test appending
		var currentArray = Defaults[key]
		currentArray.append(CodableStruct(name: "third", value: 3))
		Defaults[key] = currentArray

		#expect(Defaults[key].count == 3)
		#expect(Defaults[key][2].name == "third")
	}

	@Test
	func testDictionaryBridge() {
		let key = Defaults.Key<[String: CodableStruct]>("dictOfStructs", default: [:], suite: suite_)

		// Test empty default
		#expect(Defaults[key].isEmpty)

		// Test setting dictionary
		let dict = [
			"key1": CodableStruct(name: "value1", value: 1),
			"key2": CodableStruct(name: "value2", value: 2)
		]
		Defaults[key] = dict

		#expect(Defaults[key].count == 2)
		#expect(Defaults[key]["key1"]?.name == "value1")
		#expect(Defaults[key]["key2"]?.value == 2)

		// Test modifying
		var currentDict = Defaults[key]
		currentDict["key3"] = CodableStruct(name: "value3", value: 3)
		Defaults[key] = currentDict

		#expect(Defaults[key].count == 3)
		#expect(Defaults[key]["key3"]?.name == "value3")
	}

	@Test
	func testSetBridge() {
		let key = Defaults.Key<Set<String>>("setOfStrings", default: [], suite: suite_)

		// Test empty default
		#expect(Defaults[key].isEmpty)

		// Test setting set
		let stringSet: Set<String> = ["apple", "banana", "cherry"]
		Defaults[key] = stringSet

		#expect(Defaults[key].count == 3)
		#expect(Defaults[key].contains("apple"))
		#expect(Defaults[key].contains("banana"))
		#expect(Defaults[key].contains("cherry"))

		// Test modifying
		var currentSet = Defaults[key]
		currentSet.insert("date")
		Defaults[key] = currentSet

		#expect(Defaults[key].count == 4)
		#expect(Defaults[key].contains("date"))
	}

	@Test
	func testURLBridge() {
		let defaultURL = URL(string: "https://example.com")!
		let key = Defaults.Key<URL>("urlTest", default: defaultURL, suite: suite_)

		// Test default
		#expect(Defaults[key] == defaultURL)

		// Test setting new URL
		let newURL = URL(string: "https://test.com/path?query=value")!
		Defaults[key] = newURL

		#expect(Defaults[key] == newURL)
		#expect(Defaults[key].absoluteString == "https://test.com/path?query=value")

		// Test file URL
		let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
		Defaults[key] = fileURL

		#expect(Defaults[key] == fileURL)
		#expect(Defaults[key].isFileURL)
	}

	@Test
	func testUUIDBridge() {
		let defaultUUID = UUID()
		let key = Defaults.Key<UUID>("uuidTest", default: defaultUUID, suite: suite_)

		// Test default
		#expect(Defaults[key] == defaultUUID)

		// Test setting new UUID
		let newUUID = UUID()
		Defaults[key] = newUUID

		#expect(Defaults[key] == newUUID)
		#expect(Defaults[key].uuidString == newUUID.uuidString)

		// Test specific UUID
		let specificUUID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
		Defaults[key] = specificUUID

		#expect(Defaults[key] == specificUUID)
	}

	@Test
	func testRangeBridge() {
		let key = Defaults.Key<Range<Int>>("rangeTest", default: 0..<10, suite: suite_)

		// Test default
		#expect(Defaults[key] == 0..<10)
		#expect(Defaults[key].lowerBound == 0)
		#expect(Defaults[key].upperBound == 10)

		// Test setting new range
		let newRange = 5..<15
		Defaults[key] = newRange

		#expect(Defaults[key] == newRange)
		#expect(Defaults[key].contains(10))
		#expect(!Defaults[key].contains(15))
	}

	@Test
	func testClosedRangeBridge() {
		let key = Defaults.Key<ClosedRange<Int>>("closedRangeTest", default: 0...10, suite: suite_)

		// Test default
		#expect(Defaults[key] == 0...10)
		#expect(Defaults[key].lowerBound == 0)
		#expect(Defaults[key].upperBound == 10)

		// Test setting new range
		let newRange = 5...15
		Defaults[key] = newRange

		#expect(Defaults[key] == newRange)
		#expect(Defaults[key].contains(15)) // Unlike Range, ClosedRange includes upperBound
	}

	@Test
	func testSerializableTypeConversions() {
		// Test toValue with natively supported type
		let intValue: Int? = Int.toValue(42, type: Int.self)
		#expect(intValue == 42)

		let stringValue: String? = String.toValue("test", type: String.self)
		#expect(stringValue == "test")

		// Test toSerializable with natively supported type
		let serializedInt = Int.toSerializable(42)
		#expect(serializedInt as? Int == 42)

		let serializedString = String.toSerializable("test")
		#expect(serializedString as? String == "test")
	}

	@Test
	func testNativeTypeSupportFlags() {
		#expect(Int.isNativelySupportedType)
		#expect(String.isNativelySupportedType)
		#expect(Bool.isNativelySupportedType)
		#expect(Double.isNativelySupportedType)
		#expect(Data.isNativelySupportedType)
		#expect(Date.isNativelySupportedType)
		#expect(URL.isNativelySupportedType == false) // Uses bridge
		#expect(UUID.isNativelySupportedType == false) // Uses bridge

		// Optional types should inherit from wrapped type
		#expect((Int?).isNativelySupportedType == Int.isNativelySupportedType)
		#expect((String?).isNativelySupportedType == String.isNativelySupportedType)

		// Array of native types should be native
		#expect([String].isNativelySupportedType == true)
		#expect([Int].isNativelySupportedType == true)

		// Dictionary with String keys and native values should be native
		#expect([String: String].isNativelySupportedType == true)
		#expect([String: Int].isNativelySupportedType == true)
	}

	@Test
	func testInvalidSerializationHandling() {
		// This test verifies that the bridge handles invalid data gracefully
		let key = Defaults.Key<CodableStruct>("invalidData", default: CodableStruct(name: "fallback", value: -1), suite: suite_)

		// Manually set invalid data in UserDefaults
		suite_.set("invalid_json_data", forKey: "invalidData")

		// Should return default value when deserialization fails
		let result = Defaults[key]
		#expect(result.name == "fallback")
		#expect(result.value == -1)
	}

	@Test
	func testEnumStringKeys() {
		let key = Defaults.Key<[Category: String]>("categoryDict", default: [:], suite: suite_)
		Defaults[key] = [.electronics: "Laptop", .books: "Guide"]
		#expect(Defaults[key][.electronics] == "Laptop")
		#expect(Defaults[key][.books] == "Guide")
	}

	@Test
	func testEnumIntKeys() {
		enum Temperature: Int, Codable, Hashable, CodingKeyRepresentable {
			case freezing = -10
			case zero = 0
			case boiling = 100
		}

		let key = Defaults.Key<[Temperature: String]>("tempDict", default: [:], suite: suite_)
		Defaults[key] = [.freezing: "Cold", .zero: "Freezing", .boiling: "Hot"]
		#expect(Defaults[key][.freezing] == "Cold")
		#expect(Defaults[key][.zero] == "Freezing")
		#expect(Defaults[key][.boiling] == "Hot")
	}

	@Test
	func testRawRepresentableKeys() {
		let key = Defaults.Key<[BundleIdentifier: String]>("bundleDict", default: [:], suite: suite_)
		Defaults[key] = [BundleIdentifier("com.app"): "App"]
		#expect(Defaults[key][BundleIdentifier("com.app")] == "App")
	}

	@Test
	func testNestedDictionaries() {
		let key = Defaults.Key<[Category: [Priority: String]]>("nestedDict", default: [:], suite: suite_)
		Defaults[key] = [.electronics: [.high: "Urgent", .low: "Later"]]
		#expect(Defaults[key][.electronics]?[.high] == "Urgent")
		#expect(Defaults[key][.electronics]?[.low] == "Later")
	}

	@Test
	func testDictionaryPersistence() {
		let key1 = Defaults.Key<[Category: String]>("persistDict", default: [:], suite: suite_)
		Defaults[key1] = [.books: "Novel"]

		let key2 = Defaults.Key<[Category: String]>("persistDict", default: [:], suite: suite_)
		#expect(Defaults[key2][.books] == "Novel")
	}

	@Test
	func testDictionaryRemoval() {
		let key = Defaults.Key<[Priority: String]>("removeDict", default: [:], suite: suite_)
		Defaults[key] = [.low: "A", .high: "B"]

		var updated = Defaults[key]
		updated[.low] = nil
		Defaults[key] = updated

		#expect(Defaults[key][.low] == nil)
		#expect(Defaults[key][.high] == "B")
	}

}
