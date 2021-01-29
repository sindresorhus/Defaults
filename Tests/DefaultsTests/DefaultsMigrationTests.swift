import Defaults
import Foundation
import XCTest

/**
NativeType is a type that we want it to store in the `UserDefaults`
It should have a associated type name `CodableForm` which protocol conform to `Codable` and `Defaults.Serializable`
So we can convert the json string into `NativeType` like this.
```
guard
	let jsonString = string,
	let jsonData = jsonString.data(using: .utf8),
	let codable = try? JSONDecoder().decode([NativeType.CodableForm].self, from: jsonData)
else {
	return nil
}

return codable.toNative()
```
*/
protocol NativeType {
	associatedtype CodableForm: CodableType, Defaults.Serializable
}

/**
CodableType is a type that stored in the `UserDefaults` previously, now needs to be migrated.
It should have an associated type name `NativeForm` which is the type we want it to store in `UserDefaults`.
And it also have a `toNative()` function to convert itself into `NativeForm`.
*/
protocol CodableType: Codable {
	associatedtype NativeForm: Defaults.Serializable, NativeType
	func toNative() -> NativeForm
}

/// Let `String` conforms to NativeType, so MyBag can carry it.
extension String: NativeType {
	typealias CodableForm = Self
}

extension String: CodableType {
	typealias NativeForm = Self

	func toNative() -> Self {
		self
	}
}

struct TimeZone: Defaults.Serializable & Hashable, NativeType {
	/// Associated `CodableForm` to `CodableTimeZone`
	typealias CodableForm = CodableTimeZone

	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}

struct CodableTimeZone: Codable, Defaults.Serializable, CodableType {
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

	func migration(_ object: String?) -> Any? {
		guard
			let jsonString = object,
			let jsonData = jsonString.data(using: .utf8)
		else {
			return nil
		}

		if let codable = try? JSONDecoder().decode(TimeZone.CodableForm.self, from: jsonData) {
			return codable.toNative()
		} else if let codable = try? JSONDecoder().decode([TimeZone.CodableForm].self, from: jsonData) {
			return codable.map { $0.toNative() }
		} else if let codable = try? JSONDecoder().decode([String: TimeZone.CodableForm].self, from: jsonData) {
			return codable.reduce(into: [String: TimeZone]()) { memo, tuple in
				memo[tuple.key] = tuple.value.toNative()
			}
		}

		return nil
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

struct MyBag<Element: Defaults.Serializable & NativeType>: BagForm, Defaults.CollectionSerializable {
	var items: [Element]

	init(_ elements: [Element]) {
		self.items = elements
	}

	static var bridge: MyBagBridge<Element> { MyBagBridge() }
}

struct MyBagBridge<Element: Defaults.Serializable & NativeType>: Defaults.Bridge {
	typealias Value = MyBag<Element>
	typealias Element = MyBag<Element>.Element
	typealias Serializable = Any

	func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		if Element.isNativelySupportedType {
			return Array(value)
		}

		return value.map { Element.bridge.serialize($0 as? Element.Value) }.compactMap { $0 }
	}

	func deserialize(_ object: Serializable?) -> Value? {
		if Element.isNativelySupportedType {
			guard let array = object as? [Element] else {
				return nil
			}

			return Value(array)
		}

		guard
			let array = object as? [Element.Serializable],
			let elements = array.map({ Element.bridge.deserialize($0) }).compactMap({ $0 }) as? [Element]
		else {
			return nil
		}

		return Value(elements)
	}

	func migration(_ object: String?) -> Any? {
		guard
			let jsonString = object,
			let jsonData = jsonString.data(using: .utf8),
			let elements = try? JSONDecoder().decode([Element.CodableForm].self, from: jsonData)
		else {
			return nil
		}

		return MyBag(elements.map { $0.toNative() }.compactMap { $0 })
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

	func testArrayToNativeArray() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeArrayKey"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String]?>(keyName)
		let newValue = "d"
		Defaults[key]?.append(newValue)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayToNativeCollectionType() {
		let text = "[\"a\",\"b\",\"c\"]"
		let keyName = "arrayToNativeCollectionType"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<MyBag<String>?>(keyName)
		let newValue = "d"
		Defaults[key]?.insert(element: newValue, at: 3)
		XCTAssertEqual(Defaults[key]?[0], "a")
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
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[0].name = newName
		XCTAssertEqual(Defaults[key]?[0].name, newName)
	}

	func testArrayAndCodableElementToNativeSet() {
		let text = "[{\"id\":\"0\", \"name\": \"Asia/Taipei\"}]"
		let keyName = "testArrayAndCodableElementToNativeSet"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<Set<TimeZone>?>(keyName)
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
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}

	func testDictionaryAndCodableValueToNativeDictionary() {
		let text = "{\"0\": {\"id\":\"0\", \"name\": \"Asia/Taipei\"} }"
		let keyName = "codableArrayAndCodableElementToNativeArray"
		UserDefaults.standard.set(text, forKey: keyName)
		let key = Defaults.Key<[String: TimeZone]?>(keyName)
		XCTAssertEqual(Defaults[key]?["0"]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?["0"]?.name = newName
		XCTAssertEqual(Defaults[key]?["0"]?.name, newName)
	}
}
