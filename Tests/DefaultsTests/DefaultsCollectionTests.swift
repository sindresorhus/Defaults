import Foundation
import XCTest
import Defaults

struct Bag<Element: Defaults.Serializable>: Defaults.CollectionSerializable {
	var items: [Element]

	init(items: [Element]) {
		self.items = items
	}

	init(_ elements: [Element]) {
		self.items = elements
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


private let fixtureCollection = ["Juice", "Apple", "Banana"]

extension Defaults.Keys {
	fileprivate static let collection = Key<Bag<String>>("collection", default: Bag(items: fixtureCollection))
	fileprivate static let collectionArray = Key<[Bag<String>]>("collectionArray", default: [Bag(items: fixtureCollection)])
	fileprivate static let collectionDictionary = Key<[String: Bag<String>]>("collectionDictionary", default: ["0": Bag(items: fixtureCollection)])
}

final class DefaultsCollectionTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Bag<String>>("independentCollectionKey", default: Bag(items: fixtureCollection))
		Defaults[key].insert(element: "123", at: 0)
		XCTAssertEqual(Defaults[key][0], "123")
	}

	func testOptionalKey() {
		let key = Defaults.Key<Bag<String>?>("independentCollectionOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = Bag(items: [])
		Defaults[key]?.insert(element: fixtureCollection[0], at: 0)
		XCTAssertEqual(Defaults[key]?[0], fixtureCollection[0])
		Defaults[key]?.insert(element: fixtureCollection[1], at: 1)
		XCTAssertEqual(Defaults[key]?[1], fixtureCollection[1])
	}

	func testArrayKey() {
		let key = Defaults.Key<[Bag<String>]>("independentCollectionArrayKey", default: [Bag(items: [fixtureCollection[0]])])
		Defaults[key].append(Bag(items: [fixtureCollection[1]]))
		XCTAssertEqual(Defaults[key][1][0], fixtureCollection[1])
		Defaults[key][0].insert(element: fixtureCollection[2], at: 1)
		XCTAssertEqual(Defaults[key][0][1], fixtureCollection[2])
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[Bag<String>]?>("independentCollectionArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [Bag(items: [fixtureCollection[0]])]
		Defaults[key]?.append(Bag(items: [fixtureCollection[1]]))
		XCTAssertEqual(Defaults[key]?[1][0], fixtureCollection[1])
		Defaults[key]?[0].insert(element: fixtureCollection[2], at: 1)
		XCTAssertEqual(Defaults[key]?[0][1], fixtureCollection[2])
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Bag<String>]]>("independentCollectionNestedArrayKey", default: [[Bag(items: [fixtureCollection[0]])]])
		Defaults[key][0].append(Bag(items: [fixtureCollection[1]]))
		Defaults[key].append([Bag(items: [fixtureCollection[2]])])
		XCTAssertEqual(Defaults[key][0][0][0], fixtureCollection[0])
		XCTAssertEqual(Defaults[key][0][1][0], fixtureCollection[1])
		XCTAssertEqual(Defaults[key][1][0][0], fixtureCollection[2])
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Bag<String>]]>("independentCollectionArrayDictionaryKey", default: [["0": Bag(items: [fixtureCollection[0]])]])
		Defaults[key][0]["1"] = Bag(items: [fixtureCollection[1]])
		Defaults[key].append(["0": Bag(items: [fixtureCollection[2]])])
		XCTAssertEqual(Defaults[key][0]["0"]?[0], fixtureCollection[0])
		XCTAssertEqual(Defaults[key][0]["1"]?[0], fixtureCollection[1])
		XCTAssertEqual(Defaults[key][1]["0"]?[0], fixtureCollection[2])
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Bag<String>]>("independentCollectionDictionaryKey", default: ["0": Bag(items: [fixtureCollection[0]])])
		Defaults[key]["0"]?.insert(element: fixtureCollection[1], at: 1)
		Defaults[key]["1"] = Bag(items: [fixtureCollection[2]])
		XCTAssertEqual(Defaults[key]["0"]?[0], fixtureCollection[0])
		XCTAssertEqual(Defaults[key]["0"]?[1], fixtureCollection[1])
		XCTAssertEqual(Defaults[key]["1"]?[0], fixtureCollection[2])
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Bag<String>]?>("independentCollectionDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": Bag(items: [fixtureCollection[0]])]
		Defaults[key]?["0"]?.insert(element: fixtureCollection[1], at: 1)
		Defaults[key]?["1"] = Bag(items: [fixtureCollection[2]])
		XCTAssertEqual(Defaults[key]?["0"]?[0], fixtureCollection[0])
		XCTAssertEqual(Defaults[key]?["0"]?[1], fixtureCollection[1])
		XCTAssertEqual(Defaults[key]?["1"]?[0], fixtureCollection[2])
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Bag<String>]]>("independentCollectionDictionaryArrayKey", default: ["0": [Bag(items: [fixtureCollection[0]])]])
		Defaults[key]["0"]?[0].insert(element: fixtureCollection[1], at: 1)
		Defaults[key]["1"] = [Bag(items: [fixtureCollection[2]])]
		XCTAssertEqual(Defaults[key]["0"]?[0][0], fixtureCollection[0])
		XCTAssertEqual(Defaults[key]["0"]?[0][1], fixtureCollection[1])
		XCTAssertEqual(Defaults[key]["1"]?[0][0], fixtureCollection[2])
	}

	func testType() {
		Defaults[.collection].insert(element: "123", at: 0)
		XCTAssertEqual(Defaults[.collection][0], "123")
	}

	func testArrayType() {
		Defaults[.collectionArray].append(Bag(items: [fixtureCollection[0]]))
		Defaults[.collectionArray][0].insert(element: "123", at: 0)
		XCTAssertEqual(Defaults[.collectionArray][0][0], "123")
		XCTAssertEqual(Defaults[.collectionArray][1][0], fixtureCollection[0])
	}

	func testDictionaryType() {
		Defaults[.collectionDictionary]["1"] = Bag(items: [fixtureCollection[0]])
		Defaults[.collectionDictionary]["0"]?.insert(element: "123", at: 0)
		XCTAssertEqual(Defaults[.collectionDictionary]["0"]?[0], "123")
		XCTAssertEqual(Defaults[.collectionDictionary]["1"]?[0], fixtureCollection[0])
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Bag<String>>("observeCollectionKeyCombine", default: .init(items: fixtureCollection))
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCollection[0], item), (item, fixtureCollection[0])].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
			}

			expect.fulfill()
		}

		Defaults[key].insert(element: item, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<Bag<String>?>("observeCollectionOptionalKeyCombine")
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(String?, String?)] = [(nil, fixtureCollection[0]), (fixtureCollection[0], item), (item, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0?[0])
				XCTAssertEqual(expected.1, tuples[index].1?[0])
			}

			expect.fulfill()
		}

		Defaults[key] = Bag(items: fixtureCollection)
		Defaults[key]?.insert(element: item, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[Bag<String>]>("observeCollectionArrayKeyCombine", default: [.init(items: fixtureCollection)])
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCollection[0], item), (item, fixtureCollection[0])].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0][0])
				XCTAssertEqual(expected.1, tuples[index].1[0][0])
			}

			expect.fulfill()
		}

		Defaults[key][0].insert(element: item, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: Bag<String>]>("observeCollectionArrayKeyCombine", default: ["0": .init(items: fixtureCollection)])
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCollection[0], item), (item, fixtureCollection[0])].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"]?[0])
				XCTAssertEqual(expected.1, tuples[index].1["0"]?[0])
			}

			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(element: item, at: 0)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bag<String>>("observeCollectionKey", default: .init(items: fixtureCollection))
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0], fixtureCollection[0])
			XCTAssertEqual(change.newValue[0], item)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].insert(element: item, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<Bag<String>?>("observeCollectionOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue?[0], fixtureCollection[0])
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .init(items: fixtureCollection)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[Bag<String>]>("observeCollectionArrayKey", default: [.init(items: fixtureCollection)])
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0][0], fixtureCollection[0])
			XCTAssertEqual(change.newValue[0][0], item)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][0].insert(element: item, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: Bag<String>]>("observeCollectionDictionaryKey", default: ["0": .init(items: fixtureCollection)])
		let item = "Grape"
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"]?[0], fixtureCollection[0])
			XCTAssertEqual(change.newValue["0"]?[0], item)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(element: item, at: 0)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
