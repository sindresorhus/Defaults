import Foundation
import Observation
import Testing

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

@Suite(.serialized)
final class ObservableDefaultTests {
	init() {
		Defaults.removeAll()
		Defaults[.test] = defaultValue
	}

	deinit {
		Defaults.removeAll()
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithMemberSyntax() {
		let model = TestModelWithMemberSyntax()
		#expect(model.testValue == defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		#expect(userDefaultsValue == defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		#expect(model.testValue == newValue)
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithDotSyntax() {
		let model = TestModelWithDotSyntax()
		#expect(model.testValue == defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		#expect(userDefaultsValue == defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		#expect(model.testValue == newValue)
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithFunctionCall() {
		let model = TestModelWithFunctionCall()
		#expect(model.testValue == defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		#expect(userDefaultsValue == defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		#expect(model.testValue == newValue)
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithProperty() {
		let model = TestModelWithProperty()
		#expect(model.testValue == defaultValue)

		let userDefaultsValue = UserDefaults.standard.string(forKey: testKey)
		#expect(userDefaultsValue == defaultValue)

		UserDefaults.standard.set(newValue, forKey: testKey)
		#expect(model.testValue == newValue)
	}
}
