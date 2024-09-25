import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private enum FixtureEnum: String, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	fileprivate static let `enum` = Key<FixtureEnum>("enum", default: .tenMinutes, suite: suite_)
	fileprivate static let enumArray = Key<[FixtureEnum]>("array_enum", default: [.tenMinutes], suite: suite_)
	fileprivate static let enumDictionary = Key<[String: FixtureEnum]>("dictionary_enum", default: ["0": .tenMinutes], suite: suite_)
}

@Suite(.serialized)
final class DefaultsEnumTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<FixtureEnum>("independentEnumKey", default: .tenMinutes, suite: suite_)
		#expect(Defaults[key] == .tenMinutes)
		Defaults[key] = .halfHour
		#expect(Defaults[key] == .halfHour)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<FixtureEnum?>("independentEnumOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = .tenMinutes
		#expect(Defaults[key] == .tenMinutes)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[FixtureEnum]>("independentEnumArrayKey", default: [.tenMinutes], suite: suite_)
		#expect(Defaults[key][0] == .tenMinutes)
		Defaults[key].append(.halfHour)
		#expect(Defaults[key][0] == .tenMinutes)
		#expect(Defaults[key][1] == .halfHour)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[FixtureEnum]?>("independentEnumArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [.tenMinutes]
		Defaults[key]?.append(.halfHour)
		#expect(Defaults[key]?[0] == .tenMinutes)
		#expect(Defaults[key]?[1] == .halfHour)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[FixtureEnum]]>("independentEnumNestedArrayKey", default: [[.tenMinutes]], suite: suite_)
		#expect(Defaults[key][0][0] == .tenMinutes)
		Defaults[key][0].append(.halfHour)
		Defaults[key].append([.oneHour])
		#expect(Defaults[key][0][1] == .halfHour)
		#expect(Defaults[key][1][0] == .oneHour)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: FixtureEnum]]>("independentEnumArrayDictionaryKey", default: [["0": .tenMinutes]], suite: suite_)
		#expect(Defaults[key][0]["0"] == .tenMinutes)
		Defaults[key][0]["1"] = .halfHour
		Defaults[key].append(["0": .oneHour])
		#expect(Defaults[key][0]["1"] == .halfHour)
		#expect(Defaults[key][1]["0"] == .oneHour)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: FixtureEnum]>("independentEnumDictionaryKey", default: ["0": .tenMinutes], suite: suite_)
		#expect(Defaults[key]["0"] == .tenMinutes)
		Defaults[key]["1"] = .halfHour
		#expect(Defaults[key]["0"] == .tenMinutes)
		#expect(Defaults[key]["1"] == .halfHour)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: FixtureEnum]?>("independentEnumDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": .tenMinutes]
		#expect(Defaults[key]?["0"] == .tenMinutes)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [FixtureEnum]]>("independentEnumDictionaryKey", default: ["0": [.tenMinutes]], suite: suite_)
		#expect(Defaults[key]["0"]?[0] == .tenMinutes)
		Defaults[key]["0"]?.append(.halfHour)
		Defaults[key]["1"] = [.oneHour]
		#expect(Defaults[key]["0"]?[1] == .halfHour)
		#expect(Defaults[key]["1"]?[0] == .oneHour)
	}

	@Test
	func testType() {
		#expect(Defaults[.enum] == .tenMinutes)
		Defaults[.enum] = .halfHour
		#expect(Defaults[.enum] == .halfHour)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.enumArray][0] == .tenMinutes)
		Defaults[.enumArray][0] = .oneHour
		#expect(Defaults[.enumArray][0] == .oneHour)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.enumDictionary]["0"] == .tenMinutes)
		Defaults[.enumDictionary]["0"] = .halfHour
		#expect(Defaults[.enumDictionary]["0"] == .halfHour)
	}
}
