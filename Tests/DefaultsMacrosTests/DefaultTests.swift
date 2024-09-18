import XCTest

import Defaults
@testable import DefaultsMacros

private let testKey = "testKey"
private let defaultValue = "defaultValue"
private let newValue = "newValue"

extension Defaults.Keys {
	static let test = Defaults.Key(testKey, default: defaultValue)
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
final class DefaultTests: XCTestCase {
	override class func setUp() {
		super.setUp()
		Defaults[.test] = defaultValue
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	// MARK: Member Syntax

	@Observable
	final class TestModelWithMemberSyntax {
		@Default(Defaults.Keys.test)
		@ObservationIgnored
		var testValue: String
	}

	func testMacroWithMemberSyntax() {
		let model = TestModelWithMemberSyntax()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	// MARK: Dot syntax

	@Observable
	final class TestModelWithDotSyntax {
		@Default(.test)
		@ObservationIgnored
		var testValue: String
	}

	func testMacroWithDotSyntax() {
		let model = TestModelWithDotSyntax()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	// MARK: Function call

	static func getKey() -> Defaults.Key<String> {
		return .test
	}

	@Observable
	final class TestModelWithFunctionCall {
		@Default(getKey())
		@ObservationIgnored
		var testValue: String
	}

	func testMacroWithFunctionCall() {
		let model = TestModelWithFunctionCall()
		XCTAssertEqual(model.testValue, defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		XCTAssertEqual(userDefaultsValue, defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		XCTAssertEqual(model.testValue, newValue)
	}

	// MARK: Property

	private static var key = Defaults.Keys.test

	@Observable
	final class TestModelWithProperty {
		@Default(key)
		@ObservationIgnored
		var testValue: String
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
