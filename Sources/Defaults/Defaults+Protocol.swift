import Foundation

public protocol DefaultsNativelySupportedType {
	associatedtype Property: DefaultsNativelySupportedType = Self
}

public protocol DefaultsSerializable: DefaultsNativelySupportedType {
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
