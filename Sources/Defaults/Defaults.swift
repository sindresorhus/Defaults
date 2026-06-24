// MIT License © Sindre Sorhus
import Foundation

public enum Defaults {
	/**
	Access stored values.

	```swift
	import Defaults

	extension Defaults.Keys {
	 static let quality = Key<Double>("quality", default: 0.8)
	}

	// …

	Defaults[.quality]
	//=> 0.8

	Defaults[.quality] = 0.5
	//=> 0.5

	Defaults[.quality] += 0.1
	//=> 0.6

	Defaults[.quality] = "🦄"
	//=> [Cannot assign value of type 'String' to type 'Double']
	```
	*/
	public static subscript<Value: Serializable>(key: Key<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}
}

public typealias _Defaults = Defaults
public typealias _Default = Default

extension Defaults {
	// We cannot use `Key` as the container for keys because of "Static stored properties not supported in generic types".
	/**
	Type-erased key.
	*/
	public class _AnyKey: @unchecked Sendable {
		public typealias Key = Defaults.Key

		public let name: String
		public let suite: UserDefaults

		/**
		Whether this key uses external storage.

		This property exists on the base class to allow reset() to access it without knowing the generic type.
		*/
		var usesExternalStorage: Bool { false }

		@_alwaysEmitIntoClient
		fileprivate init(name: String, suite: UserDefaults) {
			runtimeWarn(
				isValidKeyPath(name: name),
				"The key name must be ASCII, not start with @, and cannot contain a dot (.)."
			)

			self.name = name
			self.suite = suite
		}

		/**
		Reset the item back to its default value.
		*/
		public func reset() {
			// Clean up external storage if applicable
			if usesExternalStorage {
				ExternalStorage.lock(for: name).with {
					if let fileID = suite.string(forKey: name) {
						ExternalStorage.delete(fileID: fileID, forKey: name)
					}
					suite.removeObject(forKey: name)
				}
			} else {
				suite.removeObject(forKey: name)
			}
		}
	}

	public typealias Keys = _AnyKey
}

extension Defaults {
	/**
	Strongly-typed key used to access values.

	You declare the defaults keys upfront with a type and default value.

	```swift
	import Defaults

	extension Defaults.Keys {
		static let quality = Key<Double>("quality", default: 0.8)
		//            ^            ^         ^                ^
		//           Key          Type   UserDefaults name   Default value
	}
	```

	- Important: The `UserDefaults` name must be ASCII, not start with `@`, and cannot contain a dot (`.`).
	*/
	public final class Key<Value: Serializable>: _AnyKey, @unchecked Sendable {
		/**
		It will be executed in these situations:

		- `UserDefaults.object(forKey: string)` returns `nil`
		- A `bridge` cannot deserialize `Value` from `UserDefaults`
		*/
		@usableFromInline
		let defaultValueGetter: () -> Value

		public var defaultValue: Value { defaultValueGetter() }

		/**
		Whether this key stores its value externally on disk instead of in UserDefaults.

		When enabled, only a reference UUID is stored in UserDefaults, while the actual data is written to disk.
		*/
		@usableFromInline
		let _usesExternalStorage: Bool

		override var usesExternalStorage: Bool { _usesExternalStorage }

		/**
		Create a key.

		- Parameter name: The name must be ASCII, not start with `@`, and cannot contain a dot (`.`).
		- Parameter defaultValue: The default value.
		- Parameter suite: The `UserDefaults` suite to store the value in.
		- Parameter iCloud: Automatically synchronize the value with ``Defaults/iCloud``.
		- Parameter externalStorage: Store the value externally on disk instead of in UserDefaults. Only works with the `.standard` suite.

		The `default` parameter should not be used if the `Value` type is an optional.
		*/
		@_alwaysEmitIntoClient
		public init(
			_ name: String,
			default defaultValue: Value,
			suite: UserDefaults = .standard,
			iCloud: Bool = false,
			externalStorage: Bool = false
		) {
			runtimeWarn(
				!externalStorage || suite == .standard,
				"External storage only works with UserDefaults.standard suite"
			)

			self._usesExternalStorage = externalStorage && suite == .standard
			self.defaultValueGetter = { defaultValue }

			super.init(name: name, suite: suite)

			if iCloud {
				if _usesExternalStorage {
					runtimeWarn(false, "iCloud is not supported with externalStorage for key '\(name)'.")
				} else {
					Defaults.iCloud.add(self)
				}
			}

			if (defaultValue as? (any _DefaultsOptionalProtocol))?._defaults_isNil == true {
				return
			}

			guard let serialized = Value.toSerializable(defaultValue) else {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			suite.register(defaults: [name: serialized])
		}

		/**
		Create a key with a dynamic default value.

		This can be useful in cases where you cannot define a static default value as it may change during the lifetime of the app.

		```swift
		extension Defaults.Keys {
			static let camera = Key<AVCaptureDevice?>("camera") { .default(for: .video) }
		}
		```

		- Parameter name: The name must be ASCII, not start with `@`, and cannot contain a dot (`.`).
		- Parameter suite: The `UserDefaults` suite to store the value in.
		- Parameter iCloud: Automatically synchronize the value with ``Defaults/iCloud``.
		- Parameter externalStorage: Store the value externally on disk instead of in UserDefaults. Only works with the `.standard` suite.
		- Parameter defaultValueGetter: The dynamic default value.

		- Note: This initializer will not set the default value in the actual `UserDefaults`. This should not matter much though. It's only really useful if you use legacy KVO bindings.
		*/
		@_alwaysEmitIntoClient
		public init(
			_ name: String,
			suite: UserDefaults = .standard,
			iCloud: Bool = false,
			externalStorage: Bool = false,
			default defaultValueGetter: @escaping () -> Value
		) {
			runtimeWarn(
				!externalStorage || suite == .standard,
				"External storage only works with UserDefaults.standard suite"
			)

			self._usesExternalStorage = externalStorage && suite == .standard
			self.defaultValueGetter = defaultValueGetter

			super.init(name: name, suite: suite)

			if iCloud {
				if _usesExternalStorage {
					runtimeWarn(false, "iCloud is not supported with externalStorage for key '\(name)'.")
				} else {
					Defaults.iCloud.add(self)
				}
			}
		}
	}
}

extension Defaults.Key {
	// We cannot declare this convenience initializer in class directly because of "@_transparent' attribute is not supported on declarations within classes".
	/**
	Create a key with an optional value.

	- Parameter name: The name must be ASCII, not start with `@`, and cannot contain a dot (`.`).
	- Parameter suite: The `UserDefaults` suite to store the value in.
	- Parameter iCloud: Automatically synchronize the value with ``Defaults/iCloud``.
	- Parameter externalStorage: Store the value externally on disk instead of in UserDefaults. Only works with the `.standard` suite.
	*/
	public convenience init<T>(
		_ name: String,
		suite: UserDefaults = .standard,
		iCloud: Bool = false,
		externalStorage: Bool = false
	) where Value == T? {
		self.init(
			name,
			default: nil,
			suite: suite,
			iCloud: iCloud,
			externalStorage: externalStorage
		)
	}

	/**
	Check whether the stored value is the default value.

	- Note: This is only for internal use because it would not work for non-equatable values.
	*/
	var _isDefaultValue: Bool {
		let defaultValue = defaultValue
		let value = suite[self]
		guard
			let defaultValue = defaultValue as? any Equatable,
			let value = value as? any Equatable
		else {
			return false
		}

		return defaultValue.isEqual(value)
	}
}

extension Defaults.Key where Value: Equatable {
	/**
	Indicates whether the value is the same as the default value.
	*/
	public var isDefaultValue: Bool { suite[self] == defaultValue }
}

extension Defaults {
	/**
	Remove all entries from the given `UserDefaults` suite.

	- Note: This only removes user-defined entries. System-defined entries will remain.
	*/
	public static func removeAll(suite: UserDefaults = .standard) {
		suite.removeAll()
	}
}

extension Defaults._AnyKey: Equatable {
	public static func == (lhs: Defaults._AnyKey, rhs: Defaults._AnyKey) -> Bool {
		lhs.name == rhs.name
			&& lhs.suite == rhs.suite
	}
}

extension Defaults._AnyKey: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(suite)
	}
}

extension Defaults {
	/**
	Observe updates to a stored value.

	- Parameter key: The key to observe updates from.
	- Parameter initial: Trigger an initial event on creation. This can be useful for setting default values on controls.

	```swift
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	// …

	Task {
		for await value in Defaults.updates(.isUnicornMode) {
			print("Value:", value)
		}
	}
	```
	*/
	public static func updates<Value: Serializable>(
		_ key: Key<Value>,
		initial: Bool = true
	) -> AsyncStream<Value> { // TODO: Make this `some AsyncSequence<Value>` when targeting macOS 15.
		AsyncStream { continuation in
			let observation = DefaultsObservation(object: key.suite, key: key.name) { _, change in
				// TODO: Use the `.deserialize` method directly.
				let value = KeyChange(change: change, defaultValue: key.defaultValue).newValue
				continuation.yield(value)
			}

			observation.start(options: initial ? [.initial] : [])

			continuation.onTermination = { _ in
				// `invalidate()` should be thread-safe, but it is not in practice.
				Task { @MainActor in
					observation.invalidate()
				}
			}
		}
	}

	/**
	Observe updates to multiple stored values.

	- Parameter keys: The keys to observe updates from.
	- Parameter initial: Trigger an initial event on creation. This can be useful for setting default values on controls.

	```swift
	Task {
		for await (foo, bar) in Defaults.updates(.foo, .bar) {
			print("Values changed:", foo, bar)
		}
	}
	```
	*/
	@_disfavoredOverload
	public static func updates<each Value: Serializable>(
		_ keys: repeat Key<each Value>,
		initial: Bool = true
	) -> AsyncStream<(repeat each Value)> {
		AsyncStream { continuation in
			func getCurrentValues() -> (repeat each Value) {
				(repeat self[each keys])
			}

			var observations = [DefaultsObservation]()

			if initial {
				continuation.yield(getCurrentValues())
			}

			for key in repeat (each keys) {
				let observation = DefaultsObservation(object: key.suite, key: key.name) { _, _  in
					continuation.yield(getCurrentValues())
				}

				observation.start(options: [])
				observations.append(observation)
			}

			let immutableObservations = observations

			continuation.onTermination = { _ in
				// `invalidate()` should be thread-safe, but it is not in practice.
				Task { @MainActor in
					for observation in immutableObservations {
						observation.invalidate()
					}
				}
			}
		}
	}

	// We still keep this as it can be useful to pass a dynamic array of keys.
	/**
	Observe updates to multiple stored values without receiving the values.

	- Parameter keys: The keys to observe updates from.
	- Parameter initial: Trigger an initial event on creation. This can be useful for setting default values on controls.

	```swift
	Task {
		for await _ in Defaults.updates([.foo, .bar]) {
			print("One of the values changed")
		}
	}
	```

	- Note: This does not include which of the values changed. Use ``Defaults/updates(_:initial:)-l03o`` if you need that.
	*/
	public static func updates(
		_ keys: [_AnyKey],
		initial: Bool = true
	) -> AsyncStream<Void> { // TODO: Make this `some AsyncSequence<Void>` when targeting macOS 15.
		AsyncStream { continuation in
			let observations = keys.indexed().map { index, key in
				let observation = DefaultsObservation(object: key.suite, key: key.name) { _, _ in
					continuation.yield()
				}

				// Ensure we only trigger a single initial event.
				observation.start(options: initial && index == 0 ? [.initial] : [])

				return observation
			}

			continuation.onTermination = { _ in
				// `invalidate()` should be thread-safe, but it is not in practice.
				Task { @MainActor in
					for observation in observations {
						observation.invalidate()
					}
				}
			}
		}
	}
}
