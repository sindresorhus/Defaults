import Foundation

/**
All type that able to work with `Defaults` should conform this protocol.

It should have a static variable bridge which protocol should conform to `Defaults.Bridge`.

```
struct User {
	username: String
	password: String
}

extension User: Defaults.Serializable {
	static let bridge = UserBridge()
}
```
*/
public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: DefaultsBridge

	/// Static bridge for the `Value` which cannot store natively
	static var bridge: Bridge { get }

	/// A flag to determine whether `Value` can be store natively or not
	static var isNativelySupportedType: Bool { get }
}

/**
A Bridge can do the serialization and de-serialization.

Have two associate types `Value` and `Serializable`.

- `Value`:  the type user want to use it.
- `Serializable`:  the type stored in `UserDefaults`.
- `serialize`: will be executed before storing to the `UserDefaults` .
- `deserialize`:  will be executed after retrieving its value from the `UserDefaults`.

```
struct User {
	username: String
	password: String
}

struct UserBridge: Defaults.Bridge {
	typealias Value = User
	typealias Serializable = [String: String]

	func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["username": value.username, "password": value.password]
	}

	func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
			let username = object["username"],
			let password = object["password"]
		else {
			return nil
		}

		return User(username: username, password: password)
	}
}
```
*/
public protocol DefaultsBridge {
	associatedtype Value
	associatedtype Serializable

	func serialize(_ value: Value?) -> Serializable?

	func deserialize(_ object: Serializable?) -> Value?
}

public protocol DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	/// `Collection` does not have initializer, but we need initializer to convert an array into the `Value`
	init(_ elements: [Element])
}

public protocol DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	/// Since `SetAlgebra` protocol does not conform to `Sequence`, we cannot convert a `SetAlgebra` to an `Array` directly.
	func toArray() -> [Element]
}

/// Convenience protocol for `Codable`
public protocol DefaultsCodableBridge: DefaultsBridge where Serializable == String, Value: Codable {}
