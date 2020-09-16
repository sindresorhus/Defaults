#if canImport(Combine)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Defaults {
	final class Observable<Value: Codable>: ObservableObject {
		let objectWillChange = ObservableObjectPublisher()
		private var observation: DefaultsObservation?
		private let key: Defaults.Key<Value>

		var value: Value {
			get { Defaults[key] }
			set {
				objectWillChange.send()
				Defaults[key] = newValue
			}
		}

		init(_ key: Key<Value>) {
			self.key = key

			self.observation = Defaults.observe(key, options: [.prior]) { [weak self] change in
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
public struct Default<Value: Codable>: DynamicProperty {
	public typealias Publisher = AnyPublisher<Defaults.KeyChange<Value>, Never>

	private let key: Defaults.Key<Value>
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
			Toggle("Toggle Unicorn", isOn: $hasUnicorn)
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
#endif
