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
		get { items[position] }
		set { items[position] = newValue }
	}
}

struct MyBag<Element: Defaults.Serializable & Defaults.NativeType>: Defaults.CollectionSerializable, Defaults.NativeType, BagForm {
	typealias CodableForm = [Element.CodableForm]

	var items: [Element]

	init(_ elements: [Element]) {
		self.items = elements
	}
}

private func setCodable<Value: Codable>(forKey keyName: String, data: Value) {
	guard
		let text = try? JSONEncoder().encode(data),
		let string = String(data: text, encoding: .utf8)
	else {
		XCTAssert(false)
		return
	}

	UserDefaults.standard.set(string, forKey: keyName)
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
		let data = answer.data(using: .utf8)
		setCodable(forKey: keyName, data: data)
		let key = Defaults.Key<Data?>(keyName)
		XCTAssertEqual(answer, String(data: Defaults[key]!, encoding: .utf8))
		let newName = " Hank Chen"
		Defaults[key]?.append(newName.data(using: .utf8)!)
		XCTAssertEqual(answer + newName, String(data: Defaults[key]!, encoding: .utf8))
	}

	func testArrayDataToNativeCollectionData() {
		let answer = "Hello World!"
		let keyName = "arrayDataToNativeCollectionData"
		let data = answer.data(using: .utf8)
		setCodable(forKey: keyName, data: [data])
		let key = Defaults.Key<MyBag<Data>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(answer, String(data: Defaults[key]!.first!, encoding: .utf8))
		let newName = " Hank Chen"
		Defaults[key]?[0].append(newName.data(using: .utf8)!)
		XCTAssertEqual(answer + newName, String(data: Defaults[key]!.first!, encoding: .utf8))
	}

	func testDateToNativeDate() {
		let date = Date()
		let keyName = "dateToNativeDate"
		setCodable(forKey: keyName, data: date)
		let key = Defaults.Key<Date?>(keyName)
		XCTAssertEqual(date, Defaults[key])
		let newDate = Date()
		Defaults[key] = newDate
		XCTAssertEqual(newDate, Defaults[key])
	}

	func testDateToNativeCollectionDate() {
		let date = Date()
		let keyName = "dateToNativeCollectionDate"
		setCodable(forKey: keyName, data: [date])
		let key = Defaults.Key<MyBag<Date>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(date, Defaults[key]!.first)
		let newDate = Date()
		Defaults[key]?[0] = newDate
		XCTAssertEqual(newDate, Defaults[key]!.first)
	}

	func testBoolToNativeBool() {
		let bool = false
		let keyName = "boolToNativeBool"
		setCodable(forKey: keyName, data: bool)
		let key = Defaults.Key<Bool?>(keyName)
		XCTAssertEqual(Defaults[key], bool)
		let newBool = true
		Defaults[key] = newBool
		XCTAssertEqual(Defaults[key], newBool)
	}

	func testBoolToNativeCollectionBool() {
		let bool = false
		let keyName = "boolToNativeCollectionBool"
		setCodable(forKey: keyName, data: [bool])
		let key = Defaults.Key<MyBag<Bool>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], bool)
		let newBool = true
		Defaults[key]?[0] = newBool
		XCTAssertEqual(Defaults[key]?[0], newBool)
	}

	func testIntToNativeInt() {
		let int = Int.min
		let keyName = "intToNativeInt"
		setCodable(forKey: keyName, data: int)
		let key = Defaults.Key<Int?>(keyName)
		XCTAssertEqual(Defaults[key], int)
		let newInt = Int.max
		Defaults[key] = newInt
		XCTAssertEqual(Defaults[key], newInt)
	}

	func testIntToNativeCollectionInt() {
		let int = Int.min
		let keyName = "intToNativeCollectionInt"
		setCodable(forKey: keyName, data: [int])
		let key = Defaults.Key<MyBag<Int>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], int)
		let newInt = Int.max
		Defaults[key]?[0] = newInt
		XCTAssertEqual(Defaults[key]?[0], newInt)
	}

	func testUIntToNativeUInt() {
		let uInt = UInt.min
		let keyName = "uIntToNativeUInt"
		setCodable(forKey: keyName, data: uInt)
		let key = Defaults.Key<UInt?>(keyName)
		XCTAssertEqual(Defaults[key], uInt)
		let newUInt = UInt.max
		Defaults[key] = newUInt
		XCTAssertEqual(Defaults[key], newUInt)
	}

	func testUIntToNativeCollectionUInt() {
		let uInt = UInt.min
		let keyName = "uIntToNativeCollectionUInt"
		setCodable(forKey: keyName, data: [uInt])
		let key = Defaults.Key<MyBag<UInt>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], uInt)
		let newUInt = UInt.max
		Defaults[key]?[0] = newUInt
		XCTAssertEqual(Defaults[key]?[0], newUInt)
	}

	func testDoubleToNativeDouble() {
		let double = Double.zero
		let keyName = "doubleToNativeDouble"
		setCodable(forKey: keyName, data: double)
		let key = Defaults.Key<Double?>(keyName)
		XCTAssertEqual(Defaults[key], double)
		let newDouble = Double.infinity
		Defaults[key] = newDouble
		XCTAssertEqual(Defaults[key], newDouble)
	}

	func testDoubleToNativeCollectionDouble() {
		let double = Double.zero
		let keyName = "doubleToNativeCollectionDouble"
		setCodable(forKey: keyName, data: [double])
		let key = Defaults.Key<MyBag<Double>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], double)
		let newDouble = Double.infinity
		Defaults[key]?[0] = newDouble
		XCTAssertEqual(Defaults[key]?[0], newDouble)
	}

	func testFloatToNativeFloat() {
		let float = Float.zero
		let keyName = "floatToNativeFloat"
		setCodable(forKey: keyName, data: float)
		let key = Defaults.Key<Float?>(keyName)
		XCTAssertEqual(Defaults[key], float)
		let newFloat = Float.infinity
		Defaults[key] = newFloat
		XCTAssertEqual(Defaults[key], newFloat)
	}

	func testFloatToNativeCollectionFloat() {
		let float = Float.zero
		let keyName = "floatToNativeCollectionFloat"
		setCodable(forKey: keyName, data: [float])
		let key = Defaults.Key<MyBag<Float>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0], float)
		let newFloat = Float.infinity
		Defaults[key]?[0] = newFloat
		XCTAssertEqual(Defaults[key]?[0], newFloat)
	}

	func testArrayToNativeOptionalArray() {
		let keyName = "arrayToNativeArrayKey"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<[String]?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.append(newValue)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayToNativeArray() {
		let keyName = "arrayToNativeArrayKey"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<[String]>(keyName, default: [])
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key].append(newValue)
		XCTAssertEqual(Defaults[key][0], "a")
		XCTAssertEqual(Defaults[key][1], "b")
		XCTAssertEqual(Defaults[key][2], "c")
		XCTAssertEqual(Defaults[key][3], newValue)
	}

	func testArrayToNativeSet() {
		let keyName = "arrayToNativeSet"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<Set<String>?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.insert(newValue)
		XCTAssertEqual(Defaults[key], Set(["a", "b", "c", "d"]))
	}

	func testArrayToNativeCollectionType() {
		let keyName = "arrayToNativeCollectionType"
		setCodable(forKey: keyName, data: ["a", "b", "c"])
		let key = Defaults.Key<MyBag<String>?>(keyName)
		Defaults.migration(key)
		let newValue = "d"
		Defaults[key]?.insert(element: newValue, at: 3)
		XCTAssertEqual(Defaults[key]?[0], "a")
		XCTAssertEqual(Defaults[key]?[1], "b")
		XCTAssertEqual(Defaults[key]?[2], "c")
		XCTAssertEqual(Defaults[key]?[3], newValue)
	}

	func testArrayAndCodableElementToNativeCollectionType() {
		let keyName = "arrayAndCodableElementToNativeCollectionType"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<MyBag<TimeZone>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(element: .init(id: "1", name: newName), at: 1)
		XCTAssertEqual(Defaults[key]?[1].name, newName)
	}

	func testCodableToNativeType() {
		let keyName = "codableCodableToNativeType"
		setCodable(forKey: keyName, data: CodableTimeZone(id: "0", name: "Asia/Taipei"))
		let key = Defaults.Key<TimeZone>(keyName, default: .init(id: "1", name: "Asia/Tokio"))
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key].name = newName
		XCTAssertEqual(Defaults[key].name, newName)
	}

	func testCodableToNativeOptionalType() {
		let keyName = "codableCodableToNativeOptionalType"
		setCodable(forKey: keyName, data: CodableTimeZone(id: "0", name: "Asia/Taipei"))
		let key = Defaults.Key<TimeZone?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?.name = newName
		XCTAssertEqual(Defaults[key]?.name, newName)
	}

	func testArrayAndCodableElementToNativeArray() {
		let keyName = "codableArrayAndCodableElementToNativeArray"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[TimeZone]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?[0].id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?[0].name = newName
		XCTAssertEqual(Defaults[key]?[0].name, newName)
	}

	func testArrayAndCodableElementToNativeSet() {
		let keyName = "arrayAndCodableElementToNativeSet"
		setCodable(forKey: keyName, data: [CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<Set<TimeZone>?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei")]))
		let newId = "1"
		let newName = "Asia/Tokyo"
		Defaults[key]?.insert(.init(id: newId, name: newName))
		XCTAssertEqual(Defaults[key], Set([TimeZone(id: "0", name: "Asia/Taipei"), TimeZone(id: newId, name: newName)]))
	}

	func testDictionaryToNativelyDictionary() {
		let keyName = "codableDictionaryToNativelyDictionary"
		setCodable(forKey: keyName, data: ["Hank": "Chen"])
		let key = Defaults.Key<[String: String]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?["Hank"], "Chen")
	}

	func testDictionaryAndCodableValueToNativeDictionary() {
		let keyName = "codableArrayAndCodableElementToNativeArray"
		setCodable(forKey: keyName, data: ["0": CodableTimeZone(id: "0", name: "Asia/Taipei")])
		let key = Defaults.Key<[String: TimeZone]?>(keyName)
		Defaults.migration(key)
		XCTAssertEqual(Defaults[key]?["0"]?.id, "0")
		let newName = "Asia/Tokyo"
		Defaults[key]?["0"]?.name = newName
		XCTAssertEqual(Defaults[key]?["0"]?.name, newName)
	}
}
