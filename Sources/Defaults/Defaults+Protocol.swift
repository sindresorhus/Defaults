import Foundation

public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: DefaultsBridge
	associatedtype Property = Self

	// Static bridge for the `Value` which cannot store natively
	static var bridge: Bridge { get }

	// A flag to determine whether `Value` can be store natively or not
	static var isNativelySupportedType: Bool { get }
}

public protocol DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	init(_ elements: [Element])
}

public protocol DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	// We cannot convert a `SetAlgebra` to an `Array` directly
	func toArray() -> [Element]
}

public protocol DefaultsBridge {
	// The type of Value of `Key<Value>`
	associatedtype Value

	// This type should be one of the NativelySupportedType
	associatedtype Serializable

	// Serialize Value to Serializable before we store it in UserDefaults
	func serialize(_ value: Value?) -> Serializable?

	// Deserialize Serializable to Value
	func deserialize(_ object: Serializable?) -> Value?
}

// Convenience protocol for `Codable`
public protocol DefaultsCodableBridge: DefaultsBridge where Serializable == String, Value: Codable {}

/**
NativeType is a type that we want it to store in the `UserDefaults`
It should have a associated type name `CodableForm` which protocol conform to `Codable` and `Defaults.Serializable`
So we can convert the json string into `NativeType` like this.
```
guard
	let jsonString = string,
	let jsonData = jsonString.data(using: .utf8),
	let codable = try? JSONDecoder().decode(NativeType.CodableForm.self, from: jsonData)
else {
	return nil
}

return codable.toNative()
```
*/
public protocol DefaultsNativeType {
	associatedtype CodableForm: DefaultsCodableType, Defaults.Serializable
}

/**
CodableType is a type that stored in the `UserDefaults` previously, now needs to be migrated.
It should have an associated type name `NativeForm` which is the type we want it to store in `UserDefaults`.
And it also have a `toNative()` function to convert itself into `NativeForm`.
*/
public protocol DefaultsCodableType: Codable {
	associatedtype NativeForm: Defaults.Serializable, DefaultsNativeType
	func toNative() -> NativeForm
}
