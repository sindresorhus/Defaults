import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

struct DefaultsSetAlgebra<Element: Defaults.Serializable & Hashable>: SetAlgebra {
	var store = Set<Element>()

	init() {}

	init(_ sequence: __owned some Sequence<Element>) {
		self.store = Set(sequence)
	}

	init(_ store: Set<Element>) {
		self.store = store
	}

	func contains(_ member: Element) -> Bool {
		store.contains(member)
	}

	func union(_ other: Self) -> Self {
		Self(store.union(other.store))
	}

	func intersection(_ other: Self) -> Self {
		var defaultsSetAlgebra = Self()
		defaultsSetAlgebra.store = store.intersection(other.store)
		return defaultsSetAlgebra
	}

	func symmetricDifference(_ other: Self) -> Self {
		var defaultedSetAlgebra = Self()
		defaultedSetAlgebra.store = store.symmetricDifference(other.store)
		return defaultedSetAlgebra
	}

	@discardableResult
	mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
		store.insert(newMember)
	}

	mutating func remove(_ member: Element) -> Element? {
		store.remove(member)
	}

	mutating func update(with newMember: Element) -> Element? {
		store.update(with: newMember)
	}

	mutating func formUnion(_ other: Self) {
		store.formUnion(other.store)
	}

	mutating func formSymmetricDifference(_ other: Self) {
		store.formSymmetricDifference(other.store)
	}

	mutating func formIntersection(_ other: Self) {
		store.formIntersection(other.store)
	}
}

extension DefaultsSetAlgebra: Defaults.SetAlgebraSerializable {
	func toArray() -> [Element] {
		Array(store)
	}
}

private let fixtureSetAlgebra = 0
private let fixtureSetAlgebra1 = 1
private let fixtureSetAlgebra2 = 2
private let fixtureSetAlgebra3 = 3

extension Defaults.Keys {
	fileprivate static let setAlgebra = Key<DefaultsSetAlgebra<Int>>("setAlgebra", default: .init([fixtureSetAlgebra]), suite: suite_)
	fileprivate static let setAlgebraArray = Key<[DefaultsSetAlgebra<Int>]>("setAlgebraArray", default: [.init([fixtureSetAlgebra])], suite: suite_)
	fileprivate static let setAlgebraDictionary = Key<[String: DefaultsSetAlgebra<Int>]>("setAlgebraDictionary", default: ["0": .init([fixtureSetAlgebra])], suite: suite_)
}

@Suite(.serialized)
final class DefaultsSetAlgebraTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Int>>("independentSetAlgebraKey", default: .init([fixtureSetAlgebra]), suite: suite_)
		Defaults[key].insert(fixtureSetAlgebra)
		#expect(Defaults[key] == .init([fixtureSetAlgebra]))
		Defaults[key].insert(fixtureSetAlgebra1)
		#expect(Defaults[key] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<DefaultsSetAlgebra<Int>?>("independentSetAlgebraOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = .init([fixtureSetAlgebra])
		Defaults[key]?.insert(fixtureSetAlgebra)
		#expect(Defaults[key] == .init([fixtureSetAlgebra]))
		Defaults[key]?.insert(fixtureSetAlgebra1)
		#expect(Defaults[key] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]>("independentSetAlgebraArrayKey", default: [.init([fixtureSetAlgebra])], suite: suite_)
		Defaults[key][0].insert(fixtureSetAlgebra1)
		Defaults[key].append(.init([fixtureSetAlgebra2]))
		Defaults[key][1].insert(fixtureSetAlgebra3)
		#expect(Defaults[key][0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key][1] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[DefaultsSetAlgebra<Int>]?>("independentSetAlgebraArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
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
		let key = Defaults.Key<[[DefaultsSetAlgebra<Int>]]>("independentSetAlgebraNestedArrayKey2", default: [[.init([fixtureSetAlgebra])]], suite: suite_)
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
		let key = Defaults.Key<[[String: DefaultsSetAlgebra<Int>]]>("independentSetAlgebraArrayDictionaryKey", default: [["0": .init([fixtureSetAlgebra])]], suite: suite_)
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
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]>("independentSetAlgebraDictionaryKey", default: ["0": .init([fixtureSetAlgebra])], suite: suite_)
		Defaults[key]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[key]["1"] = .init([fixtureSetAlgebra2])
		Defaults[key]["1"]?.insert(fixtureSetAlgebra3)
		#expect(Defaults[key]["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[key]["1"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: DefaultsSetAlgebra<Int>]?>("independentSetAlgebraDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
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
		let key = Defaults.Key<[String: [DefaultsSetAlgebra<Int>]]>("independentSetAlgebraDictionaryArrayKey", default: ["0": [.init([fixtureSetAlgebra])]], suite: suite_)
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
		let (inserted, _) = Defaults[.setAlgebra].insert(fixtureSetAlgebra)
		#expect(!inserted)
		Defaults[.setAlgebra].insert(fixtureSetAlgebra1)
		#expect(Defaults[.setAlgebra] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
	}

	@Test
	func testArrayType() {
		Defaults[.setAlgebraArray][0].insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraArray].append(.init([fixtureSetAlgebra2]))
		Defaults[.setAlgebraArray][1].insert(fixtureSetAlgebra3)
		#expect(Defaults[.setAlgebraArray][0] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[.setAlgebraArray][1] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}

	@Test
	func testDictionaryType() {
		Defaults[.setAlgebraDictionary]["0"]?.insert(fixtureSetAlgebra1)
		Defaults[.setAlgebraDictionary]["1"] = .init([fixtureSetAlgebra2])
		Defaults[.setAlgebraDictionary]["1"]?.insert(fixtureSetAlgebra3)
		#expect(Defaults[.setAlgebraDictionary]["0"] == .init([fixtureSetAlgebra, fixtureSetAlgebra1]))
		#expect(Defaults[.setAlgebraDictionary]["1"] == .init([fixtureSetAlgebra2, fixtureSetAlgebra3]))
	}
}
