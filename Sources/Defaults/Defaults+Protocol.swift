import Foundation

public protocol DefaultsNativelySupportedType: Codable {}

/**
DefaultsGenericCollectionType should exist because of overlapping conformances
We cannot use the syntax below:
```
extension Set: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.SetBridge<Element> { return Defaults.SetBridge<Element> }
}

//
extension Set: Defaults.Serializable where Element: Defaults.NativelySupportedType {
	public static var bridge: Defaults.SetNativeBridge<Element> { return Defaults.SetNativeBridge<Element> }
}
```
So we have to create a new protocol to deal with `Set<Element: NativelySupportedType>`
*/
public protocol DefaultsGenericCollectionType {
	typealias Value = GenericBridge.Value
	typealias Serializable = GenericBridge.Serializable
	associatedtype GenericBridge: DefaultsBridge
	static var bridge: GenericBridge { get }
}

public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: DefaultsBridge
	static var bridge: Bridge { get }
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


public protocol DefaultsCodableBridge: Defaults.Bridge where Serializable == String, Value: Codable {}
