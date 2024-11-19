import Defaults
import DefaultsMacros
import Foundation
import Observation
import Testing

private let animalKey = "animalKey"
private let defaultAnimal = "cat"
private let newAnimal = "unicorn"

private let colorKey = "colorKey"
private let defaultColor = "blue"
private let newColor = "purple"

extension Defaults.Keys {
	static let animal = Defaults.Key(animalKey, default: defaultAnimal)
	static let color = Defaults.Key(colorKey, default: defaultColor)
}

func getKey() -> Defaults.Key<String> {
	.animal
}

let keyProperty = Defaults.Keys.animal

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithDotSyntax: Sendable {
	@ObservableDefault(.animal)
	@ObservationIgnored
	var animal: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithFunctionCall {
	@ObservableDefault(getKey())
	@ObservationIgnored
	var animal: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
final class TestModelWithProperty {
	@ObservableDefault(keyProperty)
	@ObservationIgnored
	var animal: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithMemberSyntax {
	@ObservableDefault(Defaults.Keys.animal)
	@ObservationIgnored
	var animal: String
}

@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
@Observable
private final class TestModelWithMultipleValues {
	@ObservableDefault(.animal)
	@ObservationIgnored
	var animal: String

	@ObservableDefault(.color)
	@ObservationIgnored
	var color: String
}

@Suite(.serialized)
final class ObservableDefaultTests {
	init() {
		Defaults.removeAll()
		Defaults[.animal] = defaultAnimal
		Defaults[.color] = defaultColor
	}

	deinit {
		Defaults.removeAll()
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithMemberSyntax() async {
		let model = TestModelWithMemberSyntax()
		#expect(model.animal == defaultAnimal)
 
		let userDefaultsValue = UserDefaults.standard.string(forKey: animalKey)
		#expect(userDefaultsValue == defaultAnimal)
 
		await confirmation { confirmation in
			_ = withObservationTracking {
				model.animal
			} onChange: {
				confirmation()
			}
 
			UserDefaults.standard.set(newAnimal, forKey: animalKey)
		}
 
		#expect(model.animal == newAnimal)
	}
 
	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithDotSyntax() async {
		let model = TestModelWithDotSyntax()
		#expect(model.animal == defaultAnimal)
 
		let userDefaultsValue = UserDefaults.standard.string(forKey: animalKey)
		#expect(userDefaultsValue == defaultAnimal)
 
		await confirmation { confirmation in
			_ = withObservationTracking {
				model.animal
			} onChange: {
				confirmation()
			}
 
			UserDefaults.standard.set(newAnimal, forKey: animalKey)
		}
 
		#expect(model.animal == newAnimal)
	}
 
	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithFunctionCall() async {
		let model = TestModelWithFunctionCall()
		#expect(model.animal == defaultAnimal)
 
		let userDefaultsValue = UserDefaults.standard.string(forKey: animalKey)
		#expect(userDefaultsValue == defaultAnimal)
 
		await confirmation { confirmation in
			_ = withObservationTracking {
				model.animal
			} onChange: {
				confirmation()
			}
 
			UserDefaults.standard.set(newAnimal, forKey: animalKey)
		}
 
		#expect(model.animal == newAnimal)
	}
 
	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithProperty() async {
		let model = TestModelWithProperty()
		#expect(model.animal == defaultAnimal)
 
		let userDefaultsValue = UserDefaults.standard.string(forKey: animalKey)
		#expect(userDefaultsValue == defaultAnimal)
 
		await confirmation { confirmation in
			_ = withObservationTracking {
				model.animal
			} onChange: {
				confirmation()
			}
 
			UserDefaults.standard.set(newAnimal, forKey: animalKey)
		}
 
		#expect(model.animal == newAnimal)
	}

	@available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
	@Test
	func testMacroWithMultipleValues() async {
		let model = TestModelWithMultipleValues()
		#expect(model.animal == defaultAnimal)
		#expect(model.color == defaultColor)

		await confirmation(expectedCount: 2) { confirmation in
			_ = withObservationTracking {
				model.animal
			} onChange: {
				confirmation()
			}

			_ = withObservationTracking {
				model.color
			} onChange: {
				confirmation()
			}

			UserDefaults.standard.set(newAnimal, forKey: animalKey)
			UserDefaults.standard.set(newColor, forKey: colorKey)
		}

		#expect(model.animal == newAnimal)
		#expect(model.color == newColor)
	}
}
