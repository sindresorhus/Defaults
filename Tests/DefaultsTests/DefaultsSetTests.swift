import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private let fixtureSet = Set(1...5)

extension Defaults.Keys {
	fileprivate static let set = Key<Set<Int>>("setInt", default: fixtureSet, suite: suite_)
}

@Suite(.serialized)
final class DefaultsSetTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<Set<Int>>("independentSetKey", default: fixtureSet, suite: suite_)
		#expect(Defaults[key].count == fixtureSet.count)
		Defaults[key].insert(6)
		#expect(Defaults[key] == Set(1...6))
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Set<Int>?>("independentSetOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = fixtureSet
		#expect(Defaults[key]?.count == fixtureSet.count)
		Defaults[key]?.insert(6)
		#expect(Defaults[key] == Set(1...6))
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[Set<Int>]>("independentSetArrayKey", default: [fixtureSet], suite: suite_)
		#expect(Defaults[key][0].count == fixtureSet.count)
		Defaults[key][0].insert(6)
		#expect(Defaults[key][0] == Set(1...6))
		Defaults[key].append(Set(1...4))
		#expect(Defaults[key][1] == Set(1...4))
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: Set<Int>]>("independentSetArrayKey", default: ["0": fixtureSet], suite: suite_)
		#expect(Defaults[key]["0"]?.count == fixtureSet.count)
		Defaults[key]["0"]?.insert(6)
		#expect(Defaults[key]["0"] == Set(1...6))
		Defaults[key]["1"] = Set(1...4)
		#expect(Defaults[key]["1"] == Set(1...4))
	}
}
