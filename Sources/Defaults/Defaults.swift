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

extension Defaults {
	// We cannot use `Key` as the container for keys because of "Static stored properties not supported in generic types".
	/**
	Type-erased key.
	*/
	public class _AnyKey {
		public typealias Key = Defaults.Key

		public let name: String
		public let suite: UserDefaults

		fileprivate init(name: String, suite: UserDefaults) {
			self.name = name
			self.suite = suite
		}

		/**
		Reset the item back to its default value.
		*/
		public func reset() {
			suite.removeObject(forKey: name)
		}
	}
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

	- Warning: The key must be ASCII, not start with `@`, and cannot contain a dot (`.`).
	*/
	public final class Key<Value: Serializable>: _AnyKey {
		/**
		It will be executed in these situations:

		- `UserDefaults.object(forKey: string)` returns `nil`
		- A `bridge` cannot deserialize `Value` from `UserDefaults`
		*/
		private let defaultValueGetter: () -> Value

		public var defaultValue: Value { defaultValueGetter() }

		/**
		Create a defaults key.

		- Parameter key: The key must be ASCII, not start with `@`, and cannot contain a dot (`.`).

		The `default` parameter should not be used if the `Value` type is an optional.
		*/
		public init(
			_ key: String,
			default defaultValue: Value,
			suite: UserDefaults = .standard
		) {
			self.defaultValueGetter = { defaultValue }

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalProtocol)?.isNil == true {
				return
			}

			guard let serialized = Value.toSerializable(defaultValue) else {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			suite.register(defaults: [name: serialized])
		}

		/**
		Create a defaults key with a dynamic default value.
		
		This can be useful in cases where you cannot define a static default value as it may change during the lifetime of the app.

		```swift
		extension Defaults.Keys {
			static let camera = Key<AVCaptureDevice?>("camera") { .default(for: .video) }
		}
		```

		- Parameter key: The key must be ASCII, not start with `@`, and cannot contain a dot (`.`).

		- Note: This initializer will not set the default value in the actual `UserDefaults`. This should not matter much though. It's only really useful if you use legacy KVO bindings.
		*/
		public init(
			_ key: String,
			suite: UserDefaults = .standard,
			default defaultValueGetter: @escaping () -> Value
		) {
			self.defaultValueGetter = defaultValueGetter

			super.init(name: key, suite: suite)
		}

		/**
		Create a defaults key with an optional value.

		- Parameter key: The key must be ASCII, not start with `@`, and cannot contain a dot (`.`).
		*/
		public convenience init<T>(
			_ key: String,
			suite: UserDefaults = .standard
		) where Value == T? {
			self.init(key, default: nil, suite: suite)
		}
	}
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
	public typealias Keys = _AnyKey

	/**
	Types that conform to this protocol can be used with `Defaults`.

	The type should have a static variable `bridge` which should reference an instance of a type that conforms to `Defaults.Bridge`.

	```swift
	struct User {
		username: String
		password: String
	}

	extension User: Defaults.Serializable {
		static let bridge = UserBridge()
	}
	```
	*/
	public typealias Serializable = _DefaultsSerializable

	public typealias CollectionSerializable = _DefaultsCollectionSerializable
	public typealias SetAlgebraSerializable = _DefaultsSetAlgebraSerializable

	/**
	Ambiguous bridge selector protocol that lets you select your preferred bridge when there are multiple possibilities.

	```swift
	enum Interval: Int, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
		case tenMinutes = 10
		case halfHour = 30
		case oneHour = 60
	}
	```

	By default, if an `enum` conforms to `Codable` and `Defaults.Serializable`, it will use the `CodableBridge`, but by conforming to `Defaults.PreferRawRepresentable`, we can switch the bridge back to `RawRepresentableBridge`.
	*/
	public typealias PreferRawRepresentable = _DefaultsPreferRawRepresentable

	/**
	Ambiguous bridge selector protocol that lets you select your preferred bridge when there are multiple possibilities.
	*/
	public typealias PreferNSSecureCoding = _DefaultsPreferNSSecureCoding

	/**
	A `Bridge` is responsible for serialization and deserialization.

	It has two associated types `Value` and `Serializable`.

	- `Value`: The type you want to use.
	- `Serializable`: The type stored in `UserDefaults`.
	- `serialize`: Executed before storing to the `UserDefaults` .
	- `deserialize`: Executed after retrieving its value from the `UserDefaults`.

	```swift
	struct User {
		username: String
		password: String
	}

	extension User {
		static let bridge = UserBridge()
	}

	struct UserBridge: Defaults.Bridge {
		typealias Value = User
		typealias Serializable = [String: String]

		func serialize(_ value: Value?) -> Serializable? {
			guard let value else {
				return nil
			}

			return [
				"username": value.username,
				"password": value.password
			]
		}

		func deserialize(_ object: Serializable?) -> Value? {
			guard
				let object,
				let username = object["username"],
				let password = object["password"]
			else {
				return nil
			}

			return User(
				username: username,
				password: password
			)
		}
	}
	```
	*/
	public typealias Bridge = _DefaultsBridge

	public typealias RangeSerializable = _DefaultsRange & _DefaultsSerializable

	/**
	Convenience protocol for `Codable`.
	*/
	typealias CodableBridge = _DefaultsCodableBridge
}
