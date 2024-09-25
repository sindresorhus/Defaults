import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private struct Item: Equatable, Hashable {
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

private let fixtureSetAlgebra = Item(name: "Apple", count: 10)
private let fixtureSetAlgebra1 = Item(name: "Banana", count: 20)
private let fixtureSetAlgebra2 = Item(name: "Grape", count: 30)
private let fixtureSetAlgebra3 = Item(name: "Guava", count: 40)

extension Defaults.Keys {
	fileprivate static let setAlgebraCustomElement = Key<DefaultsSetAlgebra<Item>>("setAlgebraCustomElement", default: .init([fixtureSetAlgebra]), suite: suite_)
	fileprivate static let setAlgebraCustomElementArray = Key<[DefaultsSetAlgebra<Item>]>("setAlgebraArrayCustomElement", default: [.init([fixtureSetAlgebra])], suite: suite_)
	fileprivate static let setAlgebraCustomElementDictionary = Key<[String: DefaultsSetAlgebra<Item>]>("setAlgebraDictionaryCustomElement", default: ["0": .init([fixtureSetAlgebra])], suite: suite_)
}

@Suite(.serialized)
final class DefaultsSetAlgebraCustomElementTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>>("customElement_independentSetAlgebraKey", default: .init([fixtureSetAlgebra]), suite: suite_)
		Defaults[key].insert(fixtureSetAlgebra)
		#expect(Defaults[key] == .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra1)
		#expect(Defaults[key] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Item>?>("customElement_independentSetAlgebraOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = .init([fixtureSetAlgebra])
		Defaults[key]?.insert(fixtureSetAlgebra)
		#expect(Defaults[key] == .init([fixtureSetAlgebra]))
		Defaults[key]?.insert(fixtureSetAlgebra1)
		#expect(Defaults[key] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]>("customElement_independentSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])], suite: suite_)
		Defaults[key][0].insert(fixtureSetAlgebra1)
		Defaults[key].append(.init([fixtureSetAlgebra2]))
		Defaults[key][1].insert(fixtureSetAlgebra3)
		#expect(Defaults[key][0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key][1] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Item>]?>("customElement_independentSetAlgebraArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [.init([fixtureSetAlgebra])]
		Defaults[key]?[0].insert(fixtureSetAlgebra1)
		Defaults[key]?.append(.init([fixtureSetAlgebra2]))
		Defaults[key]?[1].insert(fixtureSetAlgebra3)
		#expect(Defaults[key]?[0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key]?[1] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[DefaultsSetAlgebra<Item>]]>("customElement_independentSetAlgebraNestedArrayKey", default: [[.init([fixtureSetAlgebra])]], suite: suite_)
		Defaults[key][0][0].insert(fixtureSetAlgebra1)
		Defaults[key][0].append(.init([fixtureSetAlgebra1]))
		Defaults[key][0][1].insert(fixtureSetAlgebra2)
		Defaults[key].append([.init([fixtureSetAlgebra3])])
		Defaults[key][1][0].insert(fixtureSetAlgebra2)
		#expect(Defaults[key][0][0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key][0][1] == .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		#expect(Defaults[key][1][0] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: DefaultsSetAlgebra<Item>]]>("customElement_independentSetAlgebraArrayDictionaryKey", default: [["0": .init([fixtureSetAlgebra])]], suite: suite_)
		Defaults[key][0]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key][0]["1"] = .init([fixtureSetAlgebra1])
		Defaults[key][0]["1"]?.insert(fixtureSetAlgebra2)
		Defaults[key].append(["0": .init([fixtureSetAlgebra3])])
		Defaults[key][1]["0"]?.insert(fixtureSetAlgebra2)
		#expect(Defaults[key][0]["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key][0]["1"] == .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		#expect(Defaults[key][1]["0"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]>("customElement_independentSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])], suite: suite_)
		Defaults[key]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]["1"]?.insert(fixtureSetAlgebra3)
		#expect(Defaults[key]["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key]["1"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Item>]?>("customElement_independentSetAlgebraDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": .init([fixtureSetAlgebra])]
		Defaults[key]?["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]?["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]?["1"]?.insert(fixtureSetAlgebra3)
		#expect(Defaults[key]?["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key]?["1"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [DefaultsSetAlgebra<Item>]]>("customElement_independentSetAlgebraDictionaryArrayKey", default: ["0": [.init([fixtureSetAlgebra])]], suite: suite_)
		Defaults[key]["0"]?[0].insert(fixtureSetAlgebra1)
		Defaults[key]["0"]?.append(.init([fixtureSetAlgebra1]))
		Defaults[key]["0"]?[1].insert(fixtureSetAlgebra2)
		Defaults[key]["1"] = [.init([fixtureSetAlgebra3])]
		Defaults[key]["1"]?[0].insert(fixtureSetAlgebra2)
		#expect(Defaults[key]["0"]?[0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key]["0"]?[1] == .init([fixtureSetAlgebra1, fixtureSetAlgebra2]))
		#expect(Defaults[key]["1"]?[0] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testType() {
		let (inserted, _) = Defaults[.setAlgebraCustomElement].insert(fixtureSetAlgebra)
		#expect(!inserted)
		Defaults[.setAlgebraCustomElement].insert(fixtureSetAlgebra1)
		#expect(Defaults[.setAlgebraCustomElement] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testArrayType() {
		Defaults[.setAlgebraCustomElementArray][0].insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraCustomElementArray].append(.init([fixtureSetAlgebra2]))
		Defaults[.setAlgebraCustomElementArray][1].insert(fixtureSetAlgebra3)
		#expect(Defaults[.setAlgebraCustomElementArray][0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[.setAlgebraCustomElementArray][1] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryType() {
		Defaults[.setAlgebraCustomElementDictionary]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraCustomElementDictionary]["1"] = .init([fixtureSetAlgebra2])
		Defaults[.setAlgebraCustomElementDictionary]["1"]?.insert(fixtureSetAlgebra3)
		#expect(Defaults[.setAlgebraCustomElementDictionary]["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[.setAlgebraCustomElementDictionary]["1"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}
}
