import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

private struct Unicorn: Codable, Defaults.Serializable {
	var isUnicorn: Bool
}

private let fixtureCodable = Unicorn(isUnicorn: true)

@objc(UnicornCodableAndNSSecureCoding)
private final class UnicornCodableAndNSSecureCoding: NSObject, NSSecureCoding, Codable, Defaults.Serializable {
	static let supportsSecureCoding = true

	func encode(with coder: NSCoder) {}

	init?(coder: NSCoder) {}

	override init() {
		super.init()
	}
}

@objc(UnicornCodableAndPreferNSSecureCoding)
private final class UnicornCodableAndPreferNSSecureCoding: NSObject, NSSecureCoding, Codable, Defaults.Serializable, Defaults.PreferNSSecureCoding {
	static let supportsSecureCoding = true

	func encode(with coder: NSCoder) {}

	init?(coder: NSCoder) {}

	override init() {
		super.init()
	}
}

extension Defaults.Keys {
	fileprivate static let codable = Key<Unicorn>("codable", default: fixtureCodable, suite: suite_)
	fileprivate static let codableArray = Key<[Unicorn]>("codable", default: [fixtureCodable], suite: suite_)
	fileprivate static let codableDictionary = Key<[String: Unicorn]>("codable", default: ["0": fixtureCodable], suite: suite_)
}

@Suite(.serialized)
final class DefaultsCodableTests {
	init() {
		// TODO: Convert all the keys to use a prefix and then remove based on the prefix.
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<Unicorn>("independentCodableKey", default: fixtureCodable, suite: suite_)
		#expect(Defaults[key].isUnicorn)
		Defaults[key].isUnicorn = false
		#expect(!Defaults[key].isUnicorn)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Unicorn?>("independentCodableOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = Unicorn(isUnicorn: true)
		#expect(Defaults[key]?.isUnicorn ?? false)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[Unicorn]>("independentCodableArrayKey", default: [fixtureCodable], suite: suite_)
		#expect(Defaults[key][0].isUnicorn)
		Defaults[key].append(Unicorn(isUnicorn: false))
		#expect(Defaults[key][0].isUnicorn)
		#expect(!Defaults[key][1].isUnicorn)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[Unicorn]?>("independentCodableArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [fixtureCodable]
		Defaults[key]?.append(Unicorn(isUnicorn: false))
		#expect(Defaults[key]?[0].isUnicorn ?? false)
		#expect(!(Defaults[key]?[1].isUnicorn ?? false))
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[Unicorn]]>("independentCodableNestedArrayKey", default: [[fixtureCodable]], suite: suite_)
		#expect(Defaults[key][0][0].isUnicorn)
		Defaults[key].append([fixtureCodable])
		Defaults[key][0].append(Unicorn(isUnicorn: false))
		#expect(Defaults[key][0][0].isUnicorn)
		#expect(Defaults[key][1][0].isUnicorn)
		#expect(!Defaults[key][0][1].isUnicorn)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: Unicorn]]>("independentCodableArrayDictionaryKey", default: [["0": fixtureCodable]], suite: suite_)
		#expect(Defaults[key][0]["0"]?.isUnicorn ?? false)
		Defaults[key].append(["0": fixtureCodable])
		Defaults[key][0]["1"] = Unicorn(isUnicorn: false)
		#expect(Defaults[key][0]["0"]?.isUnicorn ?? false)
		#expect(Defaults[key][1]["0"]?.isUnicorn ?? false)
		#expect(!(Defaults[key][0]["1"]?.isUnicorn ?? true))
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: Unicorn]>("independentCodableDictionaryKey", default: ["0": fixtureCodable], suite: suite_)
		#expect(Defaults[key]["0"]?.isUnicorn ?? false)
		Defaults[key]["1"] = Unicorn(isUnicorn: false)
		#expect(Defaults[key]["0"]?.isUnicorn ?? false)
		#expect(!(Defaults[key]["1"]?.isUnicorn ?? true))
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Unicorn]?>("independentCodableDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": fixtureCodable]
		Defaults[key]?["1"] = Unicorn(isUnicorn: false)
		#expect(Defaults[key]?["0"]?.isUnicorn ?? false)
		#expect(!(Defaults[key]?["1"]?.isUnicorn ?? true))
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Unicorn]]>("independentCodableDictionaryArrayKey", default: ["0": [fixtureCodable]], suite: suite_)
		#expect(Defaults[key]["0"]?[0].isUnicorn ?? false)
		Defaults[key]["1"] = [fixtureCodable]
		Defaults[key]["0"]?.append(Unicorn(isUnicorn: false))
		#expect(Defaults[key]["1"]?[0].isUnicorn ?? false)
		#expect(!(Defaults[key]["0"]?[1].isUnicorn ?? true))
	}

	@Test
	func testCodableAndRawRepresentable() {
		struct Unicorn: Codable, RawRepresentable, Defaults.Serializable {
			var rawValue: String
		}

		let fixture = Unicorn(rawValue: "x")

		let key = Defaults.Key<Unicorn?>("independentKey_codableAndRawRepresentable", suite: suite_)
		Defaults[key] = fixture
		#expect(Defaults[key]?.rawValue == fixture.rawValue)
		#expect(suite_.string(forKey: key.name) == #""\#(fixture.rawValue)""#)
	}

	@Test
	func testType() {
		#expect(Defaults[.codable].isUnicorn)
		Defaults[.codable] = Unicorn(isUnicorn: false)
		#expect(!Defaults[.codable].isUnicorn)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.codableArray][0].isUnicorn)
		Defaults[.codableArray][0] = Unicorn(isUnicorn: false)
		#expect(!Defaults[.codableArray][0].isUnicorn)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.codableDictionary]["0"]?.isUnicorn ?? false)
		Defaults[.codableDictionary]["0"] = Unicorn(isUnicorn: false)
		#expect(!(Defaults[.codableDictionary]["0"]?.isUnicorn ?? true))
	}

	@Test
	func testCodableAndNSSecureCoding() {
		let fixture = UnicornCodableAndNSSecureCoding()
		let keyName = "testCodableAndNSSecureCoding"
		_ = Defaults.Key<UnicornCodableAndNSSecureCoding>(keyName, default: fixture, suite: suite_)
		#expect(UserDefaults.standard.data(forKey: keyName) == nil)
		#expect(UserDefaults.standard.string(forKey: keyName) != nil)
	}

	@Test
	func testCodableAndPreferNSSecureCoding() {
		let fixture = UnicornCodableAndPreferNSSecureCoding()
		let keyName = "testCodableAndPreferNSSecureCoding"
		_ = Defaults.Key<UnicornCodableAndPreferNSSecureCoding>(keyName, default: fixture, suite: suite_)
		#expect(UserDefaults.standard.string(forKey: keyName) == nil)
		#expect(UserDefaults.standard.data(forKey: keyName) != nil)
	}
}
