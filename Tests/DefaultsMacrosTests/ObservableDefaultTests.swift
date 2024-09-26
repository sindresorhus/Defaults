import XCTest

import Defaults
@testable import DefaultsMacros

private let testKey = "testKey"
private let defaultValue = "defaultValue"
private let newValue = "newValue"

extension Defaults.Keys {
	static let test = Defaults.Key(testKey, default: defaultValue)
}

func getKey() -> Defaults.Key<String> {
	.test
}

let keyProperty = Defaults.Keys.test

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithMemberSyntax {
	@ObservableDefault(Defaults.Keys.test)
	@ObservationIgnored
	var testValue: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithDotSyntax {
	@ObservableDefault(.test)
	@ObservationIgnored
	var testValue: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithFunctionCall {
	@ObservableDefault(getKey())
	@ObservationIgnored
	var testValue: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
final class TestModelWithProperty {
	@ObservableDefault(keyProperty)
	@ObservationIgnored
	var testValue: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
final class ObservableDefaultTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults[.test] = defaultValue
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testMacroWithMemberSyntax() {
		let model = TestModelWithMemberSyntax()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	func testMacroWithDotSyntax() {
		let model = TestModelWithDotSyntax()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	func testMacroWithFunctionCall() {
		let model = TestModelWithFunctionCall()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	func testMacroWithProperty() {
		let model = TestModelWithProperty()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}
}
