#if canImport(Combine)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Defaults {
	final class Observable<Value>: ObservableObject {
		let objectWillChange = ObservableObjectPublisher()
		private var observation: DefaultsObservation?
		private let key: Defaults.Key<Value>

		init(_ key: Key<Value>) where Value: NativelySupportedType{
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

		init(_ key: Key<Value>) where Value: Serializable{
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
extension Defaults.Observable where Value: Defaults.NativelySupportedType {
	var value: Value {
		get { Defaults[key] }
		set {
			objectWillChange.send()
			Defaults[key] = newValue
		}
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Defaults.Observable where Value: Defaults.Serializable {
	var value: Value {
		get { Defaults[key] }
		set {
			objectWillChange.send()
			Defaults[key] = newValue
		}
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct Default<Value>: DynamicProperty {
	public typealias Publisher = AnyPublisher<Defaults.KeyChange<Value>, Never>
	private let get: () -> Value
	private let set: (Value) -> Void
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
	init(_ key: Defaults.Key<Value>, _ observables: Defaults.Observable<Value>, get: @escaping () -> Value, set: @escaping (Value) -> Void) where Value: Defaults.NativelySupportedType {
		self.key = key
		self.observable = observables
		self.get = get
		self.set = set
		self.publisher = Defaults.publisher(key)
		self.projectedValue = Binding(get: get, set: set)
	}

	init(_ key: Defaults.Key<Value>, _ observable: Defaults.Observable<Value>, get: @escaping () -> Value, set: @escaping (Value) -> Void) where Value: Defaults.Serializable {
		self.key = key
		self.observable = observable
		self.get = get
		self.set = set
		self.publisher = Defaults.publisher(key)
		self.projectedValue = Binding(get: get, set: set)
	}

	public var wrappedValue: Value {
		get { get() }
		nonmutating set {
			set(newValue)
		}
	}

	public var projectedValue: Binding<Value>

	/// Combine publisher that publishes values when the `Defaults` item changes.
	public var publisher: Publisher

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
extension Default where Value: Defaults.NativelySupportedType {
	public init(_ key: Defaults.Key<Value>) {
		let observable = Defaults.Observable(key)
		self.init(key, observable, get: {
			observable.value
		}, set: { newValue in
			observable.value = newValue
		})
	}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Default where Value: Defaults.Serializable {
	public init(_ key: Defaults.Key<Value>) {
		let observable = Defaults.Observable(key)
		self.init(key, observable, get: {
			observable.value
		}, set: { newValue in
			observable.value = newValue
		})
	}
}

#endif
