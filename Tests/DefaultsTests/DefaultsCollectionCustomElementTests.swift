import Foundation
import Combine
import XCTest
import Defaults

struct Item: Defaults.Serializable, Equatable {
	let name: String
	let count: UInt
	public static let bridge = ItemBridge()
}

struct ItemBridge: Defaults.Bridge {
	public typealias Value = Item
	public typealias Serializable = [String: String]
	public func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["name": value.name, "count": String(value.count)]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
			let name = object["name"],
			let count = UInt(object["count"] ?? "0")
		else {
			return nil
		}

		return Value.init(name: name, count: count)
	}
}


private struct Bag: Collection, Defaults.Serializable {
	var items: [Item]

	init(items: [Item]) {
		self.items = items
	}

	public var startIndex: Int {
		items.startIndex
	}

	public var endIndex: Int {
		items.endIndex
	}

	public mutating func insert(element: Item, at: Int) {
		items.insert(element, at: at)
	}

	public func index(after i: Int) -> Int {
		items.index(after: i)
	}

	subscript(position: Int) -> Item {
		items[position]
	}
}

extension Bag: ExpressibleByArrayLiteral {
	init(arrayLiteral elements: Item...) {
		self.items = elements
	}
}

private let fixtureCustomCollection = Item(name: "Apple", count: 10)
private let fixtureCustomCollection1 = Item(name: "Banana", count: 20)
private let fixtureCustomCollection2 = Item(name: "Grape", count: 30)

extension Defaults.Keys {
	fileprivate static let collectionCustomElement = Key<Bag>("collectionCustomElement", default: Bag(items: [fixtureCustomCollection]))
	fileprivate static let collectionCustomElementArray = Key<[Bag]>("collectionCustomElementArray", default: [Bag(items: [fixtureCustomCollection])])
	fileprivate static let collectionCustomElementDictionary = Key<[String: Bag]>("collectionCustomElementDictionary", default: ["0": Bag(items: [fixtureCustomCollection])])
}

final class DefaultsCollectionCustomElementTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Bag>("independentCollectionCustomElementKey", default: Bag(items: [fixtureCustomCollection]))
		Defaults[key].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].insert(element: fixtureCustomCollection2, at: 2)
		XCTAssertEqual(Defaults[key][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][2], fixtureCustomCollection2)
	}

	func testOptionalKey() {
		let key = Defaults.Key<Bag?>("independentCollectionCustomElementOptionalKey")
		Defaults[key] = Bag(items: [fixtureCustomCollection])
		Defaults[key]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.insert(element: fixtureCustomCollection2, at: 2)
		XCTAssertEqual(Defaults[key]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?[2], fixtureCustomCollection2)
	}

	func testArrayKey() {
		let key = Defaults.Key<[Bag]>("independentCollectionCustomElementArrayKey", default: [Bag(items: [fixtureCustomCollection])])
		Defaults[key][0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].append(Bag(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[key][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1][0], fixtureCustomCollection2)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[Bag]?>("independentCollectionCustomElementArrayOptionalKey")
		Defaults[key] = [Bag(items: [fixtureCustomCollection])]
		Defaults[key]?[0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.append(Bag(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[key]?[0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?[0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?[1][0], fixtureCustomCollection2)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Bag]]>("independentCollectionCustomElementNestedArrayKey", default: [[Bag(items: [fixtureCustomCollection])]])
		Defaults[key][0][0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0].append(Bag(items: [fixtureCustomCollection1]))
		Defaults[key].append([Bag(items: [fixtureCustomCollection2])])
		XCTAssertEqual(Defaults[key][0][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][0][1], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][1][0], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1][0][0], fixtureCustomCollection2)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Bag]]>("independentCollectionCustomElementArrayDictionaryKey", default: [["0": Bag(items: [fixtureCustomCollection])]])
		Defaults[key][0]["0"]?.insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0]["1"] = Bag(items: [fixtureCustomCollection1])
		Defaults[key].append(["0": Bag(items: [fixtureCustomCollection2])])
		XCTAssertEqual(Defaults[key][0]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0]["0"]?[1], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0]["1"]?[0], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1]["0"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Bag]>("independentCollectionCustomElementDictionaryKey", default: ["0": Bag(items: [fixtureCustomCollection])])
		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]["1"] = Bag(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[key]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]["1"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Bag]?>("independentCollectionCustomElementDictionaryOptionalKey")
		Defaults[key] = ["0": Bag(items: [fixtureCustomCollection])]
		Defaults[key]?["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?["1"] = Bag(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[key]?["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?["1"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Bag]]>("independentCollectionCustomElementDictionaryArrayKey", default: ["0": [Bag(items: [fixtureCustomCollection])]])
		Defaults[key]["0"]?[0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key]["0"]?.append(Bag(items: [fixtureCustomCollection1]))
		Defaults[key]["1"] = [Bag(items: [fixtureCustomCollection2])]
		XCTAssertEqual(Defaults[key]["0"]?[0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]["0"]?[0][1], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]["0"]?[1][0], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]["1"]?[0][0], fixtureCustomCollection2)
	}

	func testType() {
		Defaults[.collectionCustomElement].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElement].insert(element: fixtureCustomCollection2, at: 2)
		XCTAssertEqual(Defaults[.collectionCustomElement][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[.collectionCustomElement][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[.collectionCustomElement][2], fixtureCustomCollection2)
	}

	func testArrayType() {
		Defaults[.collectionCustomElementArray][0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElementArray].append(Bag(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[.collectionCustomElementArray][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[.collectionCustomElementArray][0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[.collectionCustomElementArray][1][0], fixtureCustomCollection2)
	}

	func testDictionaryType() {
		Defaults[.collectionCustomElementDictionary]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElementDictionary]["1"] = Bag(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["1"]?[0], fixtureCustomCollection2)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Bag>("observeCollectionCustomElementKeyCombine", default: Bag(items: [fixtureCustomCollection]))
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0[0])
				XCTAssertEqual(expected.1, tuples[i].1[0])
			}

			expect.fulfill()
		}

		Defaults[key].insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<Bag?>("observeCollectionCustomElementOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(Item?, Item?)] = [(nil, fixtureCustomCollection), (fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, nil)]

		let cancellable = publisher.sink { tuples in
			for (i, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0?[0])
				XCTAssertEqual(expected.1, tuples[i].1?[0])
			}

			expect.fulfill()
		}

		Defaults[key] = Bag(items: [fixtureCustomCollection])
		Defaults[key]?.insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[Bag]>("observeCollectionCustomElementArrayKeyCombine", default: [Bag(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0[0][0])
				XCTAssertEqual(expected.1, tuples[i].1[0][0])
			}

			expect.fulfill()
		}

		Defaults[key][0].insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: Bag]>("observeCollectionCustomElementDictionaryKeyCombine", default: ["0": Bag(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0["0"]?[0])
				XCTAssertEqual(expected.1, tuples[i].1["0"]?[0])
			}

			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bag>("observeCollectionCustomElementKey", default: Bag(items: [fixtureCustomCollection]))
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0], fixtureCustomCollection)
			XCTAssertEqual(change.newValue[0], fixtureCustomCollection1)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].insert(element: fixtureCustomCollection1, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<Bag?>("observeCollectionCustomElementOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?[0], fixtureCustomCollection)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = Bag(items: [fixtureCustomCollection])
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[Bag]>("observeCollectionCustomElementArrayKey", default: [Bag(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0][0], fixtureCustomCollection)
			XCTAssertEqual(change.newValue[0][0], fixtureCustomCollection1)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][0].insert(element: fixtureCustomCollection1, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: Bag]>("observeCollectionCustomElementArrayKey", default: ["0": Bag(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"]?[0], fixtureCustomCollection)
			XCTAssertEqual(change.newValue["0"]?[0], fixtureCustomCollection1)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
