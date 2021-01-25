import Foundation
import XCTest
import Defaults

struct DefaultsSetAlgebra<Element: Defaults.Serializable & Hashable>: Defaults.SetAlgebraSerializable {
	var store = Set<Element>()

	init() {}

	init(_store: Set<Element>) {
		store = _store
	}

	func contains(_ member: Element) -> Bool {
		store.contains(member)
	}

	func union(_ other: DefaultsSetAlgebra) -> DefaultsSetAlgebra {
		DefaultsSetAlgebra(_store: store.union(other.store))
	}

	func intersection(_ other: DefaultsSetAlgebra)
		-> DefaultsSetAlgebra {
		var defaultsSetAlgebra = DefaultsSetAlgebra()
		defaultsSetAlgebra.store = store.intersection(other.store)
		return defaultsSetAlgebra
	}

	func symmetricDifference(_ other: DefaultsSetAlgebra)
		-> DefaultsSetAlgebra {
		var defaultedSetAlgebra = DefaultsSetAlgebra()
		defaultedSetAlgebra.store = store.symmetricDifference(other.store)
		return defaultedSetAlgebra
	}

	@discardableResult
	mutating func insert(_ newMember: Element)
		-> (inserted: Bool, memberAfterInsert: Element) {
		store.insert(newMember)
	}

	mutating func remove(_ member: Element) -> Element? {
		store.remove(member)
	}

	mutating func update(with newMember: Element) -> Element? {
		store.update(with: newMember)
	}

	mutating func formUnion(_ other: DefaultsSetAlgebra) {
		store.formUnion(other.store)
	}

	mutating func formSymmetricDifference(_ other: DefaultsSetAlgebra) {
		store.formSymmetricDifference(other.store)
	}

	mutating func formIntersection(_ other: DefaultsSetAlgebra) {
		store.formIntersection(other.store)
	}

	func toArray() -> [Element] {
		Array(store)
	}
}

private let fixtureSetAlgebra = 0
private let fixtureSetAlgebra1 = 1
private let fixtureSetAlgebra2 = 2
private let fixtureSetAlgebra3 = 3

extension Defaults.Keys {
	fileprivate static let setAlgebra = Key<DefaultsSetAlgebra<Int>>("setAlgebra", default: .init([fixtureSetAlgebra]))
	fileprivate static let setAlgebraArray = Key<[DefaultsSetAlgebra<Int>]>("setAlgebraArray", default: [.init([fixtureSetAlgebra])])
	fileprivate static let setAlgebraDictionary = Key<[String: DefaultsSetAlgebra<Int>]>("setAlgebraDictionary", default: ["0": .init([fixtureSetAlgebra])])
}

final class DefaultsSetAlgebraTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Int>>("independentSetAlgebraKey", default: .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testOptionalKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Int>?>("independentSetAlgebraOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = .init([fixtureSetAlgebra])
		Defaults[key]?.insert(fixtureSetAlgebra)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra]))
		Defaults[key]?.insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[key], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testArrayKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]>("independentSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])])
		Defaults[key][0].insert(fixtureSetAlgebra1)
		Defaults[key].append(.init([fixtureSetAlgebra2]))
		Defaults[key][1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key][0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key][1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]?>("independentSetAlgebraArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = [.init([fixtureSetAlgebra])]
		Defaults[key]?[0].insert(fixtureSetAlgebra1)
		Defaults[key]?.append(.init([fixtureSetAlgebra2]))
		Defaults[key]?[1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]?[0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]?[1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[DefaultsSetAlgebra<Int>]]>("independentSetAlgebraNestedArrayKey", default: [[.init([fixtureSetAlgebra])]])
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
		let key = Defaults.Key<[[String: DefaultsSetAlgebra<Int>]]>("independentSetAlgebraArrayDictionaryKey", default: [["0": .init([fixtureSetAlgebra])]])
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
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]>("independentSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])])
		Defaults[key]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]?>("independentSetAlgebraDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": .init([fixtureSetAlgebra])]
		Defaults[key]?["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]?["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]?["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[key]?["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[key]?["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [DefaultsSetAlgebra<Int>]]>("independentSetAlgebraDictionaryArrayKey", default: ["0": [.init([fixtureSetAlgebra])]])
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
		let (inserted, _) = Defaults[.setAlgebra].insert(fixtureSetAlgebra)
		XCTAssertFalse(inserted)
		Defaults[.setAlgebra].insert(fixtureSetAlgebra1)
		XCTAssertEqual(Defaults[.setAlgebra], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	func testArrayType() {
		Defaults[.setAlgebraArray][0].insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraArray].append(.init([fixtureSetAlgebra2]))
		Defaults[.setAlgebraArray][1].insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[.setAlgebraArray][0], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[.setAlgebraArray][1], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	func testDictionaryType() {
		Defaults[.setAlgebraDictionary]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraDictionary]["1"] = .init([fixtureSetAlgebra2])
		Defaults[.setAlgebraDictionary]["1"]?.insert(fixtureSetAlgebra3)
		XCTAssertEqual(Defaults[.setAlgebraDictionary]["0"], .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		XCTAssertEqual(Defaults[.setAlgebraDictionary]["1"], .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<DefaultsSetAlgebra<Int>>("observeSetAlgebraKeyCombine", default: .init([fixtureSetAlgebra]))
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Int>, DefaultsSetAlgebra<Int>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

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
		let key = Defaults.Key<DefaultsSetAlgebra<Int>?>("observeSetAlgebraOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(DefaultsSetAlgebra<Int>?, DefaultsSetAlgebra<Int>?)] = [(nil, .init([fixtureSetAlgebra])), (.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), nil)]

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
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]>("observeSetAlgebraArrayKeyCombine", default: [.init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Int>, DefaultsSetAlgebra<Int>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

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
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]>("observeSetAlgebraDictionaryKeyCombine", default: ["0": .init([fixtureSetAlgebra])])
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(DefaultsSetAlgebra<Int>, DefaultsSetAlgebra<Int>)] = [(.init([fixtureSetAlgebra]), .init([fixtureSetAlgebra, fixtureSetAlgebra1])), (.init([fixtureSetAlgebra, fixtureSetAlgebra1]), .init([fixtureSetAlgebra]))]

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
		let key = Defaults.Key<DefaultsSetAlgebra<Int>>("observeSetAlgebraKey", default: .init([fixtureSetAlgebra]))
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
		let key = Defaults.Key<DefaultsSetAlgebra<Int>?>("observeSetAlgebraOptionalKey")
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
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]>("observeSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])])
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
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]>("observeSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])])
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
