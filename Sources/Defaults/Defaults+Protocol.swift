import Foundation

/**
Types that conform to this protocol can be used with `Defaults`.

The type should have a static variable `bridge` which should reference an instance of a type that conforms to `Defaults.Bridge`.

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

	/// Static bridge for the `Value` which cannot be stored natively.
	static var bridge: Bridge { get }

	/// A flag to determine whether `Value` can be stored natively or not.
	static var isNativelySupportedType: Bool { get }
}

/**
A `Bridge` is responsible for serialization and deserialization.

It has two associated types `Value` and `Serializable`.

- `Value`: The type you want to use.
- `Serializable`: The type stored in `UserDefaults`.
- `serialize`: Executed before storing to the `UserDefaults` .
- `deserialize`: Executed after retrieving its value from the `UserDefaults`.

```
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
		guard let value = value else {
			return nil
		}

		return [
			"username": value.username,
			"password": value.password
		]
	}

	func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
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
public protocol DefaultsBridge {
	associatedtype Value
	associatedtype Serializable

	func serialize(_ value: Value?) -> Serializable?
	func deserialize(_ object: Serializable?) -> Value?
}

public protocol DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	/// `Collection` does not have a initializer, but we need a initializer to convert an array into the `Value`.
	init(_ elements: [Element])
}

public protocol DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	/// Since `SetAlgebra` protocol does not conform to `Sequence`, we cannot convert a `SetAlgebra` to an `Array` directly.
	func toArray() -> [Element]
}

/// Convenience protocol for `Codable`.
public protocol DefaultsCodableBridge: Defaults.Bridge where Serializable == String, Value: Codable {}

/**
Ambiguous bridge selector protocol. This lets you select your preferred bridge when there are multiple possibilities.

For example:

```
enum Interval: Int, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
	case tenMinutes = 10
	case halfHour = 30
	case oneHour = 60
}
```

By default, if an `enum` conforms to `Codable` and `Defaults.Serializable`, it will use the `CodableBridge`, but by conforming to `Defaults.PreferRawRepresentable`, we can switch the bridge back to `RawRepresentableBridge`.
*/
public protocol DefaultsPreferRawRepresentable: RawRepresentable {}
public protocol DefaultsPreferNSSecureCoding: NSSecureCoding {}
