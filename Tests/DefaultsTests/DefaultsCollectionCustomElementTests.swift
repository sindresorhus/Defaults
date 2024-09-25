import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private struct Item: Equatable {
	let name: String
	let count: UInt
}

extension Item: Defaults.Serializable {
	static let bridge = ItemBridge()
}

private struct ItemBridge: Defaults.Bridge {
	typealias Value = Item
	typealias Serializable = [String: String]
	func serialize(_ value: Value?) -> Serializable? {
		guard let value else {
			return nil
		}

		return ["name": value.name, "count": String(value.count)]
	}

	func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object,
			let name = object["name"],
			let count = UInt(object["count"] ?? "0")
		else {
			return nil
		}

		return Value(name: name, count: count)
	}
}

private let fixtureCustomCollection = Item(name: "Apple", count: 10)
private let fixtureCustomCollection1 = Item(name: "Banana", count: 20)
private let fixtureCustomCollection2 = Item(name: "Grape", count: 30)

extension Defaults.Keys {
	fileprivate static let collectionCustomElement = Key<Bag<Item>>("collectionCustomElement", default: .init(items: [fixtureCustomCollection]), suite: suite_)
	fileprivate static let collectionCustomElementArray = Key<[Bag<Item>]>("collectionCustomElementArray", default: [.init(items: [fixtureCustomCollection])], suite: suite_)
	fileprivate static let collectionCustomElementDictionary = Key<[String: Bag<Item>]>("collectionCustomElementDictionary", default: ["0": .init(items: [fixtureCustomCollection])], suite: suite_)
}

@Suite(.serialized)
final class DefaultsCollectionCustomElementTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<Bag<Item>>("independentCollectionCustomElementKey", default: .init(items: [fixtureCustomCollection]), suite: suite_)
		Defaults[key].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].insert(element: fixtureCustomCollection2, at: 2)
		#expect(Defaults[key][0] == fixtureCustomCollection)
		#expect(Defaults[key][1] == fixtureCustomCollection1)
		#expect(Defaults[key][2] == fixtureCustomCollection2)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Bag<Item>?>("independentCollectionCustomElementOptionalKey", suite: suite_)
		Defaults[key] = .init(items: [fixtureCustomCollection])
		Defaults[key]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.insert(element: fixtureCustomCollection2, at: 2)
		#expect(Defaults[key]?[0] == fixtureCustomCollection)
		#expect(Defaults[key]?[1] == fixtureCustomCollection1)
		#expect(Defaults[key]?[2] == fixtureCustomCollection2)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[Bag<Item>]>("independentCollectionCustomElementArrayKey", default: [.init(items: [fixtureCustomCollection])], suite: suite_)
		Defaults[key][0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].append(.init(items: [fixtureCustomCollection2]))
		#expect(Defaults[key][0][0] == fixtureCustomCollection)
		#expect(Defaults[key][0][1] == fixtureCustomCollection1)
		#expect(Defaults[key][1][0] == fixtureCustomCollection2)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[Bag<Item>]?>("independentCollectionCustomElementArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		Defaults[key] = [.init(items: [fixtureCustomCollection])]
		Defaults[key]?[0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.append(Bag(items: [fixtureCustomCollection2]))
		#expect(Defaults[key]?[0][0] == fixtureCustomCollection)
		#expect(Defaults[key]?[0][1] == fixtureCustomCollection1)
		#expect(Defaults[key]?[1][0] == fixtureCustomCollection2)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[Bag<Item>]]>("independentCollectionCustomElementNestedArrayKey", default: [[.init(items: [fixtureCustomCollection])]], suite: suite_)
		Defaults[key][0][0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0].append(.init(items: [fixtureCustomCollection1]))
		Defaults[key].append([.init(items: [fixtureCustomCollection2])])
		#expect(Defaults[key][0][0][0] == fixtureCustomCollection)
		#expect(Defaults[key][0][0][1] == fixtureCustomCollection)
		#expect(Defaults[key][0][1][0] == fixtureCustomCollection1)
		#expect(Defaults[key][1][0][0] == fixtureCustomCollection2)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Bag<Item>]]>("independentCollectionCustomElementArrayDictionaryKey", default: [["0": .init(items: [fixtureCustomCollection])]], suite: suite_)
		Defaults[key][0]["0"]?.insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0]["1"] = .init(items: [fixtureCustomCollection1])
		Defaults[key].append(["0": .init(items: [fixtureCustomCollection2])])
		#expect(Defaults[key][0]["0"]?[0] == fixtureCustomCollection)
		#expect(Defaults[key][0]["0"]?[1] == fixtureCustomCollection)
		#expect(Defaults[key][0]["1"]?[0] == fixtureCustomCollection1)
		#expect(Defaults[key][1]["0"]?[0] == fixtureCustomCollection2)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: Bag<Item>]>("independentCollectionCustomElementDictionaryKey", default: ["0": .init(items: [fixtureCustomCollection])], suite: suite_)
		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]["1"] = .init(items: [fixtureCustomCollection2])
		#expect(Defaults[key]["0"]?[0] == fixtureCustomCollection)
		#expect(Defaults[key]["0"]?[1] == fixtureCustomCollection1)
		#expect(Defaults[key]["1"]?[0] == fixtureCustomCollection2)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Bag<Item>]?>("independentCollectionCustomElementDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		Defaults[key] = ["0": .init(items: [fixtureCustomCollection])]
		Defaults[key]?["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?["1"] = .init(items: [fixtureCustomCollection2])
		#expect(Defaults[key]?["0"]?[0] == fixtureCustomCollection)
		#expect(Defaults[key]?["0"]?[1] == fixtureCustomCollection1)
		#expect(Defaults[key]?["1"]?[0] == fixtureCustomCollection2)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Bag<Item>]]>("independentCollectionCustomElementDictionaryArrayKey", default: ["0": [.init(items: [fixtureCustomCollection])]], suite: suite_)
		Defaults[key]["0"]?[0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key]["0"]?.append(.init(items: [fixtureCustomCollection1]))
		Defaults[key]["1"] = [.init(items: [fixtureCustomCollection2])]
		#expect(Defaults[key]["0"]?[0][0] == fixtureCustomCollection)
		#expect(Defaults[key]["0"]?[0][1] == fixtureCustomCollection)
		#expect(Defaults[key]["0"]?[1][0] == fixtureCustomCollection1)
		#expect(Defaults[key]["1"]?[0][0] == fixtureCustomCollection2)
	}

	@Test
	func testType() {
		Defaults[.collectionCustomElement].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElement].insert(element: fixtureCustomCollection2, at: 2)
		#expect(Defaults[.collectionCustomElement][0] == fixtureCustomCollection)
		#expect(Defaults[.collectionCustomElement][1] == fixtureCustomCollection1)
		#expect(Defaults[.collectionCustomElement][2] == fixtureCustomCollection2)
	}

	@Test
	func testArrayType() {
		Defaults[.collectionCustomElementArray][0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElementArray].append(.init(items: [fixtureCustomCollection2]))
		#expect(Defaults[.collectionCustomElementArray][0][0] == fixtureCustomCollection)
		#expect(Defaults[.collectionCustomElementArray][0][1] == fixtureCustomCollection1)
		#expect(Defaults[.collectionCustomElementArray][1][0] == fixtureCustomCollection2)
	}

	@Test
	func testDictionaryType() {
		Defaults[.collectionCustomElementDictionary]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElementDictionary]["1"] = .init(items: [fixtureCustomCollection2])
		#expect(Defaults[.collectionCustomElementDictionary]["0"]?[0] == fixtureCustomCollection)
		#expect(Defaults[.collectionCustomElementDictionary]["0"]?[1] == fixtureCustomCollection1)
		#expect(Defaults[.collectionCustomElementDictionary]["1"]?[0] == fixtureCustomCollection2)
	}
}
