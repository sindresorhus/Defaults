import Foundation

public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: DefaultsBridge

	// Static bridge for the `Value` which cannot store natively
	static var bridge: Bridge { get }

	// A flag to determine whether `Value` can be store natively or not
	static var isNativelySupportedType: Bool { get }
}

public protocol DefaultsCollectionSerializable: Collection & DefaultsSerializable {
	// Need protocol initialize to complete the generic initialization
	init(_ elements: [Element])
}

public protocol DefaultsSetAlgebraSerializable: SetAlgebra & DefaultsSerializable {
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
