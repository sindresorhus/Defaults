import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

struct Bag<Element: Defaults.Serializable>: Collection {
	var items: [Element]

	init(items: [Element]) {
		self.items = items
	}

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

extension Bag: Defaults.CollectionSerializable {
	init(_ elements: [Element]) {
		self.items = elements
	}
}

private let fixtureCollection = ["Juice", "Apple", "Banana"]

extension Defaults.Keys {
	fileprivate static let collection = Key<Bag<String>>("collection", default: Bag(items: fixtureCollection), suite: suite_)
	fileprivate static let collectionArray = Key<[Bag<String>]>("collectionArray", default: [Bag(items: fixtureCollection)], suite: suite_)
	fileprivate static let collectionDictionary = Key<[String: Bag<String>]>("collectionDictionary", default: ["0": Bag(items: fixtureCollection)], suite: suite_)
}

@Suite(.serialized)
final class DefaultsCollectionTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<Bag<String>>("independentCollectionKey", default: Bag(items: fixtureCollection), suite: suite_)
		Defaults[key].insert(element: "123", at: 0)
		#expect(Defaults[key][0] == "123")
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Bag<String>?>("independentCollectionOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = Bag(items: [])
		Defaults[key]?.insert(element: fixtureCollection[0], at: 0)
		#expect(Defaults[key]?[0] == fixtureCollection[0])
		Defaults[key]?.insert(element: fixtureCollection[1], at: 1)
		#expect(Defaults[key]?[1] == fixtureCollection[1])
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[Bag<String>]>("independentCollectionArrayKey", default: [Bag(items: [fixtureCollection[0]])], suite: suite_)
		Defaults[key].append(Bag(items: [fixtureCollection[1]]))
		#expect(Defaults[key][1][0] == fixtureCollection[1])
		Defaults[key][0].insert(element: fixtureCollection[2], at: 1)
		#expect(Defaults[key][0][1] == fixtureCollection[2])
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[Bag<String>]?>("independentCollectionArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [Bag(items: [fixtureCollection[0]])]
		Defaults[key]?.append(Bag(items: [fixtureCollection[1]]))
		#expect(Defaults[key]?[1][0] == fixtureCollection[1])
		Defaults[key]?[0].insert(element: fixtureCollection[2], at: 1)
		#expect(Defaults[key]?[0][1] == fixtureCollection[2])
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[Bag<String>]]>("independentCollectionNestedArrayKey", default: [[Bag(items: [fixtureCollection[0]])]], suite: suite_)
		Defaults[key][0].append(Bag(items: [fixtureCollection[1]]))
		Defaults[key].append([Bag(items: [fixtureCollection[2]])])
		#expect(Defaults[key][0][0][0] == fixtureCollection[0])
		#expect(Defaults[key][0][1][0] == fixtureCollection[1])
		#expect(Defaults[key][1][0][0] == fixtureCollection[2])
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Bag<String>]]>("independentCollectionArrayDictionaryKey", default: [["0": Bag(items: [fixtureCollection[0]])]], suite: suite_)
		Defaults[key][0]["1"] = Bag(items: [fixtureCollection[1]])
		Defaults[key].append(["0": Bag(items: [fixtureCollection[2]])])
		#expect(Defaults[key][0]["0"]?[0] == fixtureCollection[0])
		#expect(Defaults[key][0]["1"]?[0] == fixtureCollection[1])
		#expect(Defaults[key][1]["0"]?[0] == fixtureCollection[2])
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: Bag<String>]>("independentCollectionDictionaryKey", default: ["0": Bag(items: [fixtureCollection[0]])], suite: suite_)
		Defaults[key]["0"]?.insert(element: fixtureCollection[1], at: 1)
		Defaults[key]["1"] = Bag(items: [fixtureCollection[2]])
		#expect(Defaults[key]["0"]?[0] == fixtureCollection[0])
		#expect(Defaults[key]["0"]?[1] == fixtureCollection[1])
		#expect(Defaults[key]["1"]?[0] == fixtureCollection[2])
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Bag<String>]?>("independentCollectionDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": Bag(items: [fixtureCollection[0]])]
		Defaults[key]?["0"]?.insert(element: fixtureCollection[1], at: 1)
		Defaults[key]?["1"] = Bag(items: [fixtureCollection[2]])
		#expect(Defaults[key]?["0"]?[0] == fixtureCollection[0])
		#expect(Defaults[key]?["0"]?[1] == fixtureCollection[1])
		#expect(Defaults[key]?["1"]?[0] == fixtureCollection[2])
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Bag<String>]]>("independentCollectionDictionaryArrayKey", default: ["0": [Bag(items: [fixtureCollection[0]])]], suite: suite_)
		Defaults[key]["0"]?[0].insert(element: fixtureCollection[1], at: 1)
		Defaults[key]["1"] = [Bag(items: [fixtureCollection[2]])]
		#expect(Defaults[key]["0"]?[0][0] == fixtureCollection[0])
		#expect(Defaults[key]["0"]?[0][1] == fixtureCollection[1])
		#expect(Defaults[key]["1"]?[0][0] == fixtureCollection[2])
	}

	@Test
	func testType() {
		Defaults[.collection].insert(element: "123", at: 0)
		#expect(Defaults[.collection][0] == "123")
	}

	@Test
	func testArrayType() {
		Defaults[.collectionArray].append(Bag(items: [fixtureCollection[0]]))
		Defaults[.collectionArray][0].insert(element: "123", at: 0)
		#expect(Defaults[.collectionArray][0][0] == "123")
		#expect(Defaults[.collectionArray][1][0] == fixtureCollection[0])
	}

	@Test
	func testDictionaryType() {
		Defaults[.collectionDictionary]["1"] = Bag(items: [fixtureCollection[0]])
		Defaults[.collectionDictionary]["0"]?.insert(element: "123", at: 0)
		#expect(Defaults[.collectionDictionary]["0"]?[0] == "123")
		#expect(Defaults[.collectionDictionary]["1"]?[0] == fixtureCollection[0])
	}
}
