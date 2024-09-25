import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private enum FixtureCodableEnum: String, Hashable, Codable, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

private enum FixtureCodableEnumPreferRawRepresentable: Int, Hashable, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
	case tenMinutes = 10
	case halfHour = 30
	case oneHour = 60
}

extension Defaults.Keys {
	fileprivate static let codableEnum = Key<FixtureCodableEnum>("codable_enum", default: .oneHour, suite: suite_)
	fileprivate static let codableEnumArray = Key<[FixtureCodableEnum]>("codable_enum", default: [.oneHour], suite: suite_)
	fileprivate static let codableEnumDictionary = Key<[String: FixtureCodableEnum]>("codable_enum", default: ["0": .oneHour], suite: suite_)
}

@Suite(.serialized)
final class DefaultsCodableEnumTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<FixtureCodableEnum>("independentCodableEnumKey", default: .tenMinutes, suite: suite_)
		#expect(Defaults[key] == .tenMinutes)
		Defaults[key] = .halfHour
		#expect(Defaults[key] == .halfHour)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<FixtureCodableEnum?>("independentCodableEnumOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = .tenMinutes
		#expect(Defaults[key] == .tenMinutes)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[FixtureCodableEnum]>("independentCodableEnumArrayKey", default: [.tenMinutes], suite: suite_)
		#expect(Defaults[key][0] == .tenMinutes)
		Defaults[key][0] = .halfHour
		#expect(Defaults[key][0] == .halfHour)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[FixtureCodableEnum]?>("independentCodableEnumArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [.halfHour]
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[FixtureCodableEnum]]>("independentCodableEnumNestedArrayKey", default: [[.tenMinutes]], suite: suite_)
		#expect(Defaults[key][0][0] == .tenMinutes)
		Defaults[key].append([.halfHour])
		Defaults[key][0].append(.oneHour)
		#expect(Defaults[key][1][0] == .halfHour)
		#expect(Defaults[key][0][1] == .oneHour)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: FixtureCodableEnum]]>("independentCodableEnumArrayDictionaryKey", default: [["0": .tenMinutes]], suite: suite_)
		#expect(Defaults[key][0]["0"] == .tenMinutes)
		Defaults[key][0]["1"] = .halfHour
		Defaults[key].append(["0": .oneHour])
		#expect(Defaults[key][0]["1"] == .halfHour)
		#expect(Defaults[key][1]["0"] == .oneHour)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: FixtureCodableEnum]>("independentCodableEnumDictionaryKey", default: ["0": .tenMinutes], suite: suite_)
		#expect(Defaults[key]["0"] == .tenMinutes)
		Defaults[key]["1"] = .halfHour
		Defaults[key]["0"] = .oneHour
		#expect(Defaults[key]["0"] == .oneHour)
		#expect(Defaults[key]["1"] == .halfHour)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: FixtureCodableEnum]?>("independentCodableEnumDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": .tenMinutes]
		Defaults[key]?["1"] = .halfHour
		#expect(Defaults[key]?["0"] == .tenMinutes)
		#expect(Defaults[key]?["1"] == .halfHour)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [FixtureCodableEnum]]>("independentCodableEnumDictionaryArrayKey", default: ["0": [.tenMinutes]], suite: suite_)
		#expect(Defaults[key]["0"]?[0] == .tenMinutes)
		Defaults[key]["0"]?.append(.halfHour)
		Defaults[key]["1"] = [.oneHour]
		#expect(Defaults[key]["0"]?[0] == .tenMinutes)
		#expect(Defaults[key]["0"]?[1] == .halfHour)
		#expect(Defaults[key]["1"]?[0] == .oneHour)
	}

	@Test
	func testType() {
		#expect(Defaults[.codableEnum] == .oneHour)
		Defaults[.codableEnum] = .tenMinutes
		#expect(Defaults[.codableEnum] == .tenMinutes)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.codableEnumArray][0] == .oneHour)
		Defaults[.codableEnumArray].append(.halfHour)
		#expect(Defaults[.codableEnumArray][0] == .oneHour)
		#expect(Defaults[.codableEnumArray][1] == .halfHour)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.codableEnumDictionary]["0"] == .oneHour)
		Defaults[.codableEnumDictionary]["1"] = .halfHour
		#expect(Defaults[.codableEnumDictionary]["0"] == .oneHour)
		#expect(Defaults[.codableEnumDictionary]["1"] == .halfHour)
	}

	@Test
	func testFixtureCodableEnumPreferRawRepresentable() {
		let fixture: FixtureCodableEnumPreferRawRepresentable = .tenMinutes
		let keyName = "testFixtureCodableEnumPreferRawRepresentable"
		_ = Defaults.Key<FixtureCodableEnumPreferRawRepresentable>(keyName, default: fixture, suite: suite_)
		#expect(UserDefaults.standard.integer(forKey: keyName) != 0)
	}
}
