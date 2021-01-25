import Foundation
import XCTest
import Defaults

private struct Item: Defaults.Serializable, Equatable {
	let name: String
	let count: UInt

	static let bridge = ItemBridge()
}

private struct ItemBridge: Defaults.Bridge {
	typealias Value = Item
	typealias Serializable = [String: String]
	func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["name": value.name, "count": String(value.count)]
	}

	func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
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
	fileprivate static let collectionCustomElement = Key<Bag<Item>>("collectionCustomElement", default: .init(items: [fixtureCustomCollection]))
	fileprivate static let collectionCustomElementArray = Key<[Bag<Item>]>("collectionCustomElementArray", default: [.init(items: [fixtureCustomCollection])])
	fileprivate static let collectionCustomElementDictionary = Key<[String: Bag<Item>]>("collectionCustomElementDictionary", default: ["0": .init(items: [fixtureCustomCollection])])
}

final class DefaultsCollectionCustomElementTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Bag<Item>>("independentCollectionCustomElementKey", default: .init(items: [fixtureCustomCollection]))
		Defaults[key].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].insert(element: fixtureCustomCollection2, at: 2)
		XCTAssertEqual(Defaults[key][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][2], fixtureCustomCollection2)
	}

	func testOptionalKey() {
		let key = Defaults.Key<Bag<Item>?>("independentCollectionCustomElementOptionalKey")
		Defaults[key] = .init(items: [fixtureCustomCollection])
		Defaults[key]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.insert(element: fixtureCustomCollection2, at: 2)
		XCTAssertEqual(Defaults[key]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?[2], fixtureCustomCollection2)
	}

	func testArrayKey() {
		let key = Defaults.Key<[Bag<Item>]>("independentCollectionCustomElementArrayKey", default: [.init(items: [fixtureCustomCollection])])
		Defaults[key][0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key].append(.init(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[key][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1][0], fixtureCustomCollection2)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[Bag<Item>]?>("independentCollectionCustomElementArrayOptionalKey")
		Defaults[key] = [.init(items: [fixtureCustomCollection])]
		Defaults[key]?[0].insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?.append(Bag(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[key]?[0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?[0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?[1][0], fixtureCustomCollection2)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Bag<Item>]]>("independentCollectionCustomElementNestedArrayKey", default: [[.init(items: [fixtureCustomCollection])]])
		Defaults[key][0][0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0].append(.init(items: [fixtureCustomCollection1]))
		Defaults[key].append([.init(items: [fixtureCustomCollection2])])
		XCTAssertEqual(Defaults[key][0][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][0][1], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0][1][0], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1][0][0], fixtureCustomCollection2)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Bag<Item>]]>("independentCollectionCustomElementArrayDictionaryKey", default: [["0": .init(items: [fixtureCustomCollection])]])
		Defaults[key][0]["0"]?.insert(element: fixtureCustomCollection, at: 1)
		Defaults[key][0]["1"] = .init(items: [fixtureCustomCollection1])
		Defaults[key].append(["0": .init(items: [fixtureCustomCollection2])])
		XCTAssertEqual(Defaults[key][0]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0]["0"]?[1], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key][0]["1"]?[0], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key][1]["0"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Bag<Item>]>("independentCollectionCustomElementDictionaryKey", default: ["0": .init(items: [fixtureCustomCollection])])
		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]["1"] = .init(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[key]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]["1"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Bag<Item>]?>("independentCollectionCustomElementDictionaryOptionalKey")
		Defaults[key] = ["0": .init(items: [fixtureCustomCollection])]
		Defaults[key]?["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[key]?["1"] = .init(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[key]?["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[key]?["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[key]?["1"]?[0], fixtureCustomCollection2)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Bag<Item>]]>("independentCollectionCustomElementDictionaryArrayKey", default: ["0": [.init(items: [fixtureCustomCollection])]])
		Defaults[key]["0"]?[0].insert(element: fixtureCustomCollection, at: 1)
		Defaults[key]["0"]?.append(.init(items: [fixtureCustomCollection1]))
		Defaults[key]["1"] = [.init(items: [fixtureCustomCollection2])]
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
		Defaults[.collectionCustomElementArray].append(.init(items: [fixtureCustomCollection2]))
		XCTAssertEqual(Defaults[.collectionCustomElementArray][0][0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[.collectionCustomElementArray][0][1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[.collectionCustomElementArray][1][0], fixtureCustomCollection2)
	}

	func testDictionaryType() {
		Defaults[.collectionCustomElementDictionary]["0"]?.insert(element: fixtureCustomCollection1, at: 1)
		Defaults[.collectionCustomElementDictionary]["1"] = .init(items: [fixtureCustomCollection2])
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["0"]?[0], fixtureCustomCollection)
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["0"]?[1], fixtureCustomCollection1)
		XCTAssertEqual(Defaults[.collectionCustomElementDictionary]["1"]?[0], fixtureCustomCollection2)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Bag<Item>>("observeCollectionCustomElementKeyCombine", default: .init(items: [fixtureCustomCollection]))
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
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
		let key = Defaults.Key<Bag<Item>?>("observeCollectionCustomElementOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(Item?, Item?)] = [(nil, fixtureCustomCollection), (fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0?[0])
				XCTAssertEqual(expected.1, tuples[index].1?[0])
			}

			expect.fulfill()
		}

		Defaults[key] = .init(items: [fixtureCustomCollection])
		Defaults[key]?.insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[Bag<Item>]>("observeCollectionCustomElementArrayKeyCombine", default: [.init(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0][0])
				XCTAssertEqual(expected.1, tuples[index].1[0][0])
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
		let key = Defaults.Key<[String: Bag<Item>]>("observeCollectionCustomElementDictionaryKeyCombine", default: ["0": .init(items: [fixtureCustomCollection])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCustomCollection, fixtureCustomCollection1), (fixtureCustomCollection1, fixtureCustomCollection)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"]?[0])
				XCTAssertEqual(expected.1, tuples[index].1["0"]?[0])
			}

			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(element: fixtureCustomCollection1, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bag<Item>>("observeCollectionCustomElementKey", default: .init(items: [fixtureCustomCollection]))
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
		let key = Defaults.Key<Bag<Item>?>("observeCollectionCustomElementOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?[0], fixtureCustomCollection)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .init(items: [fixtureCustomCollection])
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[Bag<Item>]>("observeCollectionCustomElementArrayKey", default: [.init(items: [fixtureCustomCollection])])
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
		let key = Defaults.Key<[String: Bag<Item>]>("observeCollectionCustomElementArrayKey", default: ["0": .init(items: [fixtureCustomCollection])])
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
