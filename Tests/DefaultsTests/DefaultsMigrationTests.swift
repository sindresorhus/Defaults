import Defaults
import Foundation
import XCTest

struct TimeZone: Defaults.Serializable, Defaults.NativeType, Hashable {
	/// Associated `CodableForm` to `CodableTimeZone`
	typealias CodableForm = CodableTimeZone

	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}

struct CodableTimeZone: Defaults.Serializable, Defaults.CodableType {
	var id: String
	var name: String

	/// Convert from `Codable` to `Native`
	func toNative() -> TimeZone {
		TimeZone(id: id, name: name)
	}
}

struct TimeZoneBridge: Defaults.Bridge {
	typealias Value = TimeZone
	typealias Serializable = [String: Any]

	func serialize(_ value: TimeZone?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["id": value.id, "name": value.name]
	}

	func deserialize(_ object: Serializable?) -> TimeZone? {
		guard
			let dictionary = object,
			let id = dictionary["id"] as? String,
			let name = dictionary["name"] as? String
		else {
			return nil
		}

		return TimeZone(id: id, name: name)
	}
}

protocol BagForm {
	associatedtype Element
	var items: [Element] { get set }
}

extension BagForm {
	var startIndex: Int {
		items.startIndex
	}

	var endIndex: Int {
		items.endIndex
	}

	mutating func insert(element: Element, at: Int) {
		items.insert(element, at: at)
	}

	func index(after index: Int) -> Int {
		items.index(after: index)
	}

	subscript(position: Int) -> Element {
		items[position]
	}
}

struct MyBag<Element: Defaults.Serializable & Defaults.NativeType>: Defaults.NativeType, BagForm, Defaults.CollectionSerializable {
	var items: [Element]

	init(_ elements: [Element]) {
		self.items = elements
	}
}

final class DefaultsMigrationTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testDataToNativeData() {
		let answer = "Hello World!"
		let keyName = "dataToNativeData"
		let encoder = JSONEncoder()
		let data = answer.data(using: .utf8)
		guard
			let text = try? encoder.encode(data),
			let string = String(data: text, encoding: .utf8)
		else {
			XCTAssert(false)
			return
		}
		UserDefaults.standard.set(string, forKey: keyName)
		let key = Defaults.Key<Data?>(keyName)
		key.migration()
		XCTAssertEqual(answer, String(data: Defaults[key]!, encoding: .utf8))
	}

	func testArrayToNativeOptionalArray() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeArrayKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String]?>(keyName)
		key.migration()
		let newValue = "d"
		Defaults[key]?.append(newValue)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayToNativeArray() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeArrayKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String]>(keyName, default: [])
		key.migration()
		let newValue = "d"
		Defaults[key].append(newValue)
		XCTAssertEqual(Defaults[key][0], "a")
		XCTAssertEqual(Defaults[key][1], "b")
		XCTAssertEqual(Defaults[key][2], "c")
		XCTAssertEqual(Defaults[key][3], newValue)
	}

	func testArrayToNativeSet() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeSet"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<Set<String>?>(keyName)
		key.migration()
		let newValue = "d"
		Defaults[key]?.insert(newValue)
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c", "d"]))
	}

	func testArrayToNativeCollectionType() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeCollectionType"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<MyBag<String>?>(keyName)
		key.migration()
		let newValue = "d"
		Defaults[key]?.insert(element: newValue, at: 3)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayAndCodableElementToNativeCollectionType() {
		let text = "[{\"id\":\"0\", \"name\": \"Asia/Taipei\"}]"
		let keyName = "arrayAndCodableElementToNativeCollectionType"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<MyBag<TimeZone>?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(element: .init(id: "1", name: newName), at: 1)
		XCTAssertEqual(Defaults[key]?[1].name, newName)
	}

	func testCodableToNativeType() {
		let text = "{\"id\":\"0\", \"name\": \"Asia/Taipei\"}"
		let keyName = "codableCodableToNativeType"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<TimeZone?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.name = newName
		XCTAssertEqual(Defaults[key]?.name, newName)
	}

	func testArrayAndCodableElementToNativeArray() {
		let text = "[{\"id\":\"0\", \"name\": \"Asia/Taipei\"}]"
		let keyName = "codableArrayAndCodableElementToNativeArray"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[TimeZone]?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[0].name = newName
		XCTAssertEqual(Defaults[key]?[0].name, newName)
	}

	func testArrayAndCodableElementToNativeSet() {
		let text = "[{\"id\":\"0\", \"name\": \"Asia/Taipei\"}]"
		let keyName = "arrayAndCodableElementToNativeSet"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<Set<TimeZone>?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei")]))
		let newId = "1"
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(.init(id: newId, name: newName))
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei"), TimeZone(id: newId, name: newName)]))
	}

	func testDictionaryToNativelyDictionary() {
		let text = "{\"Hank\":\"Chen\"}"
		let keyName = "codableDictionaryToNativelyDictionary"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: String]?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}

	func testDictionaryAndCodableValueToNativeDictionary() {
		let text = "{\"0\": {\"id\":\"0\", \"name\": \"Asia/Taipei\"} }"
		let keyName = "codableArrayAndCodableElementToNativeArray"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: TimeZone]?>(keyName)
		key.migration()
		XCTAssertEqual(Defaults[key]?["0"]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?["0"]?.name = newName
		XCTAssertEqual(Defaults[key]?["0"]?.name, newName)
	}
}
