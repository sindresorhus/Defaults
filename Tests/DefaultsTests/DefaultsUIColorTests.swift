#if !os(macOS)
import Foundation
import UIKit
import Testing
import Defaults

private let suite_ = createSuite()

private let fixtureColor = UIColor(red: Double(103) / Double(0xFF), green: Double(132) / Double(0xFF), blue: Double(255) / Double(0xFF), alpha: 1)
private let fixtureColor1 = UIColor(red: Double(255) / Double(0xFF), green: Double(241) / Double(0xFF), blue: Double(180) / Double(0xFF), alpha: 1)
private let fixtureColor2 = UIColor(red: Double(255) / Double(0xFF), green: Double(180) / Double(0xFF), blue: Double(194) / Double(0xFF), alpha: 1)

extension Defaults.Keys {
	fileprivate static let color = Defaults.Key<UIColor>("NSColor", default: fixtureColor, suite: suite_)
	fileprivate static let colorArray = Defaults.Key<[UIColor]>("NSColorArray", default: [fixtureColor], suite: suite_)
	fileprivate static let colorDictionary = Defaults.Key<[String: UIColor]>("NSColorArray", default: ["0": fixtureColor], suite: suite_)
}

@Suite(.serialized)
final class DefaultsNSColorTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<UIColor>("independentNSColorKey", default: fixtureColor, suite: suite_)
		#expect(Defaults[key].isEqual(fixtureColor))
		Defaults[key] = fixtureColor1
		#expect(Defaults[key].isEqual(fixtureColor1))
	}

	@Test
	func testPreservesColorSpace() {
		let fixture = UIColor(displayP3Red: 1, green: 0.3, blue: 0.7, alpha: 1)
		let key = Defaults.Key<UIColor?>("independentNSColorPreservesColorSpaceKey", suite: suite_)
		Defaults[key] = fixture
		#expect(Defaults[key] == fixture)
		#expect(Defaults[key]?.cgColor.colorSpace == fixture.cgColor.colorSpace)
		#expect(Defaults[key]?.cgColor == fixture.cgColor)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<UIColor?>("independentNSColorOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = fixtureColor
		#expect(Defaults[key]?.isEqual(fixtureColor) ?? false)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[UIColor]>("independentNSColorArrayKey", default: [fixtureColor], suite: suite_)
		#expect(Defaults[key][0].isEqual(fixtureColor))
		Defaults[key].append(fixtureColor1)
		#expect(Defaults[key][1].isEqual(fixtureColor1))
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[UIColor]?>("independentNSColorOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [fixtureColor]
		Defaults[key]?.append(fixtureColor1)
		#expect(Defaults[key]?[0].isEqual(fixtureColor) ?? false)
		#expect(Defaults[key]?[1].isEqual(fixtureColor1) ?? false)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[UIColor]]>("independentNSColorNestedArrayKey", default: [[fixtureColor]], suite: suite_)
		#expect(Defaults[key][0][0].isEqual(fixtureColor))
		Defaults[key][0].append(fixtureColor1)
		Defaults[key].append([fixtureColor2])
		#expect(Defaults[key][0][1].isEqual(fixtureColor1))
		#expect(Defaults[key][1][0].isEqual(fixtureColor2))
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: UIColor]]>("independentNSColorArrayDictionaryKey", default: [["0": fixtureColor]], suite: suite_)
		#expect(Defaults[key][0]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[key][0]["1"] = fixtureColor1
		Defaults[key].append(["0": fixtureColor2])
		#expect(Defaults[key][0]["1"]?.isEqual(fixtureColor1) ?? false)
		#expect(Defaults[key][1]["0"]?.isEqual(fixtureColor2) ?? false)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: UIColor]>("independentNSColorDictionaryKey", default: ["0": fixtureColor], suite: suite_)
		#expect(Defaults[key]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[key]["1"] = fixtureColor1
		#expect(Defaults[key]["1"]?.isEqual(fixtureColor1) ?? false)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: UIColor]?>("independentNSColorDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": fixtureColor]
		Defaults[key]?["1"] = fixtureColor1
		#expect(Defaults[key]?["0"]?.isEqual(fixtureColor) ?? false)
		#expect(Defaults[key]?["1"]?.isEqual(fixtureColor1) ?? false)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [UIColor]]>("independentNSColorDictionaryArrayKey", default: ["0": [fixtureColor]], suite: suite_)
		#expect(Defaults[key]["0"]?[0].isEqual(fixtureColor) ?? false)
		Defaults[key]["0"]?.append(fixtureColor1)
		Defaults[key]["1"] = [fixtureColor2]
		#expect(Defaults[key]["0"]?[1].isEqual(fixtureColor1) ?? false)
		#expect(Defaults[key]["1"]?[0].isEqual(fixtureColor2) ?? false)
	}

	@Test
	func testType() {
		#expect(Defaults[.color].isEqual(fixtureColor))
		Defaults[.color] = fixtureColor1
		#expect(Defaults[.color].isEqual(fixtureColor1))
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.colorArray][0].isEqual(fixtureColor))
		Defaults[.colorArray][0] = fixtureColor1
		#expect(Defaults[.colorArray][0].isEqual(fixtureColor1))
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.colorDictionary]["0"]?.isEqual(fixtureColor) ?? false)
		Defaults[.colorDictionary]["0"] = fixtureColor1
		#expect(Defaults[.colorDictionary]["0"]?.isEqual(fixtureColor1) ?? false)
	}
}
#endif
