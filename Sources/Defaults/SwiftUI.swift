import SwiftUI
import Combine

extension Defaults {
	@MainActor
	final class Observable<Value: Serializable>: ObservableObject {
		private var cancellable: AnyCancellable?
		private var task: Task<Void, Never>?

		var key: Defaults.Key<Value> {
			didSet {
				if key != oldValue {
					observe()
				}
			}
		}

		var value: Value {
			get { Defaults[key] }
			set {
				Defaults[key] = newValue
			}
		}

		init(_ key: Key<Value>) {
			self.key = key

			observe()
		}

		deinit {
			task?.cancel()
		}

		func observe() {
			// We only use this on the latest OSes (as of adding this) since the backdeploy library has a lot of bugs.
			if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
				task?.cancel()

				// The `@MainActor` is important as the `.send()` method doesn't inherit the `@MainActor` from the class.
				task = .detached(priority: .userInitiated) { @MainActor [weak self, key] in
					for await _ in Defaults.updates(key) {
						guard let self else {
							return
						}

						self.objectWillChange.send()
					}
				}
			} else {
				cancellable = Defaults.publisher(key, options: [.prior])
					.sink { [weak self] change in
						guard change.isPrior else {
							return
						}

						Task { @MainActor in
							self?.objectWillChange.send()
						}
					}
			}
		}

		/**
		Reset the key back to its default value.
		*/
		func reset() {
			key.reset()
		}
	}
}

/**
Access stored values from SwiftUI.

This is similar to `@AppStorage` but it accepts a ``Defaults/Key`` and many more types.
*/
@MainActor
@propertyWrapper
public struct Default<Value: Defaults.Serializable>: DynamicProperty {
	public typealias Publisher = AnyPublisher<Defaults.KeyChange<Value>, Never>

	private let key: Defaults.Key<Value>

	@StateObject private var observable: Defaults.Observable<Value>

	/**
	Get/set a `Defaults` item and also have the view be updated when the value changes. This is similar to `@State`.

	- Important: You cannot use this in an `ObservableObject`. It's meant to be used in a `View`.

	```swift
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
		self._observable = .init(wrappedValue: .init(key))
	}

	public var wrappedValue: Value {
		get { observable.value }
		nonmutating set {
			observable.value = newValue
		}
	}

	public var projectedValue: Binding<Value> { $observable.value }

	/**
	The default value of the key.
	*/
	public var defaultValue: Value { key.defaultValue }

	/**
	Combine publisher that publishes values when the `Defaults` item changes.
	*/
	public var publisher: Publisher { Defaults.publisher(key) }

	public mutating func update() {
		observable.key = key
		_observable.update()
	}

	/**
	Reset the key back to its default value.

	```swift
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

extension Default where Value: Equatable {
	/**
	Indicates whether the value is the same as the default value.
	*/
	public var isDefaultValue: Bool { wrappedValue == defaultValue }
}

extension Defaults {
	/**
	A SwiftUI `Toggle` view that is connected to a ``Defaults/Key`` with a `Bool` value.

	The toggle works exactly like the SwiftUI `Toggle`.

	```swift
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

	```swift
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
	public struct Toggle<Label: View>: View {
		@ViewStorage private var onChange: ((Bool) -> Void)?

		private let label: () -> Label

		// Intentionally using `@ObservedObjected` over `@StateObject` so that the key can be dynamically changed.
		@ObservedObject private var observable: Defaults.Observable<Bool>

		public init(key: Defaults.Key<Bool>, @ViewBuilder label: @escaping () -> Label) {
			self.label = label
			self.observable = .init(key)
		}

		public var body: some View {
			SwiftUI.Toggle(isOn: $observable.value, label: label)
				.onChange(of: observable.value) {
					onChange?($0)
				}
		}
	}
}

extension Defaults.Toggle<Text> {
	public init(_ title: some StringProtocol, key: Defaults.Key<Bool>) {
		self.label = { Text(title) }
		self.observable = .init(key)
	}
}

extension Defaults.Toggle {
	/**
	Do something when the value changes to a different value.
	*/
	public func onChange(_ action: @escaping (Bool) -> Void) -> Self {
		onChange = action
		return self
	}
}

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
