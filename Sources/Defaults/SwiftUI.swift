#if canImport(Combine)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Defaults {
	final class Observable<Value: Serializable>: ObservableObject {
		private var cancellable: AnyCancellable?
		private let key: Defaults.Key<Value>

		let objectWillChange = ObservableObjectPublisher()

		var value: Value {
			get { Defaults[key] }
			set {
				objectWillChange.send()
				Defaults[key] = newValue
			}
		}

		init(_ key: Key<Value>) {
			self.key = key

			self.cancellable = Defaults.publisher(key, options: [.prior])
				.sink { [weak self] change in
					guard change.isPrior else {
						return
					}

					DispatchQueue.mainSafeAsync {
						self?.objectWillChange.send()
					}
				}
		}

		/// Reset the key back to its default value.
		func reset() {
			key.reset()
		}
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct Default<Value: Defaults.Serializable>: DynamicProperty {
	public typealias Publisher = AnyPublisher<Defaults.KeyChange<Value>, Never>

	private let key: Defaults.Key<Value>

	// Intentionally using `@ObservedObjected` over `@StateObject` so that the key can be dynamicaly changed.
	@ObservedObject private var observable: Defaults.Observable<Value>

	/**
	Get/set a `Defaults` item and also have the view be updated when the value changes. This is similar to `@State`.

	- Important: You cannot use this in an `ObservableObject`. It's meant to be used in a `View`.

	```
	extension Defaults.Keys {
		static let hasUnicorn = Key<Bool>("hasUnicorn", default: false)
	}

	struct ContentView: View {
		@Default(.hasUnicorn) var hasUnicorn

		var body: some View {
			Text("Has Unicorn: \(hasUnicorn)")
			Toggle("Toggle", isOn: $hasUnicorn)
			Button("Reset") {
				_hasUnicorn.reset()
			}
		}
	}
	```
	*/
	public init(_ key: Defaults.Key<Value>) {
		self.key = key
		self.observable = Defaults.Observable(key)
	}

	public var wrappedValue: Value {
		get { observable.value }
		nonmutating set {
			observable.value = newValue
		}
	}

	public var projectedValue: Binding<Value> { $observable.value }

	/// The default value of the key.
	public var defaultValue: Value { key.defaultValue }

	/// Combine publisher that publishes values when the `Defaults` item changes.
	public var publisher: Publisher { Defaults.publisher(key) }

	public mutating func update() {
		_observable.update()
	}

	/**
	Reset the key back to its default value.

	```
	extension Defaults.Keys {
		static let opacity = Key<Double>("opacity", default: 1)
	}

	struct ContentView: View {
		@Default(.opacity) var opacity

		var body: some View {
			Button("Reset") {
				_opacity.reset()
			}
		}
	}
	```
	*/
	public func reset() {
		key.reset()
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Default where Value: Equatable {
	/// Indicates whether the value is the same as the default value.
	public var isDefaultValue: Bool { wrappedValue == defaultValue }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
extension Defaults {
	/**
	Creates a SwiftUI `Toggle` view that is connected to a `Defaults` key with a `Bool` value.

	The toggle works exactly like the SwiftUI `Toggle`.

	```
	extension Defaults.Keys {
		static let showAllDayEvents = Key<Bool>("showAllDayEvents", default: false)
	}

	struct ShowAllDayEventsSetting: View {
		var body: some View {
			Defaults.Toggle("Show All-Day Events", key: .showAllDayEvents)
		}
	}
	```

	You can also listen to changes:

	```
	struct ShowAllDayEventsSetting: View {
		var body: some View {
			Defaults.Toggle("Show All-Day Events", key: .showAllDayEvents)
				// Note that this has to be directly attached to `Defaults.Toggle`. It's not `View#onChange()`.
				.onChange {
					print("Value", $0)
				}
		}
	}
	```
	*/
	public struct Toggle<Label, Key>: View where Label: View, Key: Defaults.Key<Bool> {
		@ViewStorage private var onChange: ((Bool) -> Void)?

		private let label: () -> Label

		// Intentionally using `@ObservedObjected` over `@StateObject` so that the key can be dynamicaly changed.
		@ObservedObject private var observable: Defaults.Observable<Bool>

		public init(key: Key, @ViewBuilder label: @escaping () -> Label) {
			self.label = label
			self.observable = Defaults.Observable(key)
		}

		public var body: some View {
			SwiftUI.Toggle(isOn: $observable.value, label: label)
				.onChange(of: observable.value) {
					onChange?($0)
				}
		}
	}
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
extension Defaults.Toggle where Label == Text {
	public init<S>(_ title: S, key: Defaults.Key<Bool>) where S: StringProtocol {
		self.label = { Text(title) }
		self.observable = Defaults.Observable(key)
	}
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
extension Defaults.Toggle {
	/// Do something when the value changes to a different value.
	public func onChange(_ action: @escaping (Bool) -> Void) -> Self {
		onChange = action
		return self
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
private struct ViewStorage<Value>: DynamicProperty {
	private final class ValueBox {
		var value: Value

		init(_ value: Value) {
			self.value = value
		}
	}

	@State private var valueBox: ValueBox

	var wrappedValue: Value {
		get { valueBox.value }
		nonmutating set {
			valueBox.value = newValue
		}
	}

	init(wrappedValue value: @autoclosure @escaping () -> Value) {
		self._valueBox = .init(wrappedValue: ValueBox(value()))
	}
}
#endif
