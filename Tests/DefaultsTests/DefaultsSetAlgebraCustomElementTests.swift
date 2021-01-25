import Foundation
import XCTest
import Defaults

private struct Item: Defaults.Serializable, Equatable, Hashable {
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

private let fixtureSetAlgebra = Item(name: "Apple", count: 10)
private let fixtureSetAlgebra1 = Item(name: "Banana", count: 20)
private let fixtureSetAlgebra2 = Item(name: "Grape", count: 30)
private let fixtureSetAlgebra3 = Item(name: "Guava", count: 40)

extension Defaults.Keys {
	fileprivate static let setAlgebraCustomElement = Key<DefaultsSetAlgebra<Item>>("setAlgebraCustomElement", default: .init([fixtureSetAlgebra]))
	fileprivate static let setAlgebraCustomElementArray = Key<[DefaultsSetAlgebra<Item>]>("setAlgebraArrayCustomElement", default: [.init([fixtureSetAlgebra])])
	fileprivate static let setAlgebraCustomElementDictionary = Key<[String: DefaultsSetAlgebra<Item>]>("setAlgebraDictionaryCustomElement", default: ["0": .init([fixtureSetAlgebra])])
}

final class DefaultsSetAlgebraCustomElementTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>>("independentSetAlgebraKey", default: .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testOptionalKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>?>("independentSetAlgebraOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = .init([fixtureSetAlgebra])
		Defaults[key]?.insert(fixtureSetAlgebra)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra]))
		Defaults[key]?.insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testArrayKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]>("independentSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])])
		Defaults[key][0].insert(fixtureSetAlgebra1)
		Defaults[key].append(.init([fixtureSetAlgebra2]))
		Defaults[key][1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key][0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key][1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]?>("independentSetAlgebraArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [.init([fixtureSetAlgebra])]
		Defaults[key]?[0].insert(fixtureSetAlgebra1)
		Defaults[key]?.append(.init([fixtureSetAlgebra2]))
		Defaults[key]?[1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]?[0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]?[1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[DefaultsSetAlgebra<Item>]]>("independentSetAlgebraNestedArrayKey", default: [[.init([fixtureSetAlgebra])]])
		Defaults[key][0][0].insert(fixtureSetAlgebra1)
		Defaults[key][0].append(.init([fixtureSetAlgebra1]))
		Defaults[key][0][1].insert(fixtureSetAlgebra2)
		Defaults[key].append([.init([fixtureSetAlgebra3])])
		Defaults[key][1][0].insert(fixtureSetAlgebra2)
		XCTAssertEqual(Defaults[key][0][0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key][0][1], .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		XCTAssertEqual(Defaults[key][1][0], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: DefaultsSetAlgebra<Item>]]>("independentSetAlgebraArrayDictionaryKey", default: [["0": .init([fixtureSetAlgebra])]])
		Defaults[key][0]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key][0]["1"] = .init([fixtureSetAlgebra1])
		Defaults[key][0]["1"]?.insert(fixtureSetAlgebra2)
		Defaults[key].append(["0": .init([fixtureSetAlgebra3])])
		Defaults[key][1]["0"]?.insert(fixtureSetAlgebra2)
		XCTAssertEqual(Defaults[key][0]["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key][0]["1"], .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		XCTAssertEqual(Defaults[key][1]["0"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]>("independentSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])])
		Defaults[key]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]?>("independentSetAlgebraDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": .init([fixtureSetAlgebra])]
		Defaults[key]?["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]?["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]?["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]?["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]?["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [DefaultsSetAlgebra<Item>]]>("independentSetAlgebraDictionaryArrayKey", default: ["0": [.init([fixtureSetAlgebra])]])
		Defaults[key]["0"]?[0].insert(fixtureSetAlgebra1)
		Defaults[key]["0"]?.append(.init([fixtureSetAlgebra1]))
		Defaults[key]["0"]?[1].insert(fixtureSetAlgebra2)
		Defaults[key]["1"] = [.init([fixtureSetAlgebra3])]
		Defaults[key]["1"]?[0].insert(fixtureSetAlgebra2)
		XCTAssertEqual(Defaults[key]["0"]?[0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]["0"]?[1], .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		XCTAssertEqual(Defaults[key]["1"]?[0], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testType() {
		let (inserted, _) = Defaults[.setAlgebraCustomElement].insert(fixtureSetAlgebra)
		XCTAssertFalse(inserted)
		Defaults[.setAlgebraCustomElement].insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[.setAlgebraCustomElement], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testArrayType() {
		Defaults[.setAlgebraCustomElementArray][0].insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraCustomElementArray].append(.init([fixtureSetAlgebra2]))
		Defaults[.setAlgebraCustomElementArray][1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[.setAlgebraCustomElementArray][0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[.setAlgebraCustomElementArray][1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryType() {
		Defaults[.setAlgebraCustomElementDictionary]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraCustomElementDictionary]["1"] = .init([fixtureSetAlgebra2])
		Defaults[.setAlgebraCustomElementDictionary]["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[.setAlgebraCustomElementDictionary]["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[.setAlgebraCustomElementDictionary]["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>>("observeSetAlgebraKeyCombine", default: .init([fixtureSetAlgebra]))
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Item>, DefaultsSetAlgebra<Item>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key].insert(fixtureSetAlgebra1)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>?>("observeSetAlgebraOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(DefaultsSetAlgebra<Item>?, DefaultsSetAlgebra<Item>?)] = [(nil, .init([fixtureSetAlgebra])), (.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = .init([fixtureSetAlgebra])
		Defaults[key]?.insert(fixtureSetAlgebra1)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]>("observeSetAlgebraArrayKeyCombine", default: [.init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Item>, DefaultsSetAlgebra<Item>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0[0])
				XCTAssertEqual(expected.1, tuples[index].1[0])
			}

			expect.fulfill()
		}

		Defaults[key][0].insert(fixtureSetAlgebra1)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveDictionaryKeyCombine() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]>("observeSetAlgebraDictionaryKeyCombine", default: ["0": .init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Item>, DefaultsSetAlgebra<Item>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"])
				XCTAssertEqual(expected.1, tuples[index].1["0"])
			}

			expect.fulfill()
		}

		Defaults[key]["0"]?.insert(fixtureSetAlgebra1)
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>>("observeSetAlgebraKey", default: .init([fixtureSetAlgebra]))
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, .init([fixtureSetAlgebra]))
			XCTAssertEqual(change.newValue, .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].insert(fixtureSetAlgebra1)
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>?>("observeSetAlgebraOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue, .init([fixtureSetAlgebra]))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = .init([fixtureSetAlgebra])
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]>("observeSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0], .init([fixtureSetAlgebra]))
			XCTAssertEqual(change.newValue[1], .init([fixtureSetAlgebra]))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key].append(.init([fixtureSetAlgebra]))
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictioanryKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]>("observeSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"], .init([fixtureSetAlgebra]))
			XCTAssertEqual(change.newValue["1"], .init([fixtureSetAlgebra]))
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["1"] = .init([fixtureSetAlgebra])
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
