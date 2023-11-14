import Foundation

public protocol _DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: Defaults.Bridge

	/**
	Static bridge for the `Value` which cannot be stored natively.
	*/
	static var bridge: Bridge { get }

	/**
	A flag to determine whether `Value` can be stored natively or not.
	*/
	static var isNativelySupportedType: Bool { get }
}

public protocol _DefaultsBridge {
	associatedtype Value
	associatedtype Serializable

	func serialize(_ value: Value?) -> Serializable?
	func deserialize(_ object: Serializable?) -> Value?
}

public protocol _DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	/**
	`Collection` does not have a initializer, but we need a initializer to convert an array into the `Value`.
	*/
	init(_ elements: [Element])
}

public protocol _DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	/**
	Since `SetAlgebra` protocol does not conform to `Sequence`, we cannot convert a `SetAlgebra` to an `Array` directly.
	*/
	func toArray() -> [Element]
}

public protocol _DefaultsCodableBridge: Defaults.Bridge where Serializable == String, Value: Codable {}

public protocol _DefaultsPreferRawRepresentable: RawRepresentable {}
public protocol _DefaultsPreferNSSecureCoding: NSObject, NSSecureCoding {}

// Essential properties for serializing and deserializing `ClosedRange` and `Range`.
public protocol _DefaultsRange {
	associatedtype Bound: Comparable, Defaults.Serializable

	var lowerBound: Bound { get }
	var upperBound: Bound { get }

	init(uncheckedBounds: (lower: Bound, upper: Bound))
}

/**
Essential properties for synchronizing a key value store.
*/
public protocol _DefaultsKeyValueStore {
	func object(forKey aKey: String) -> Any?

	func set(_ anObject: Any?, forKey aKey: String)

	func removeObject(forKey aKey: String)

	@discardableResult
	func synchronize() -> Bool
}

protocol _DefaultsLockProtocol {
	static func make() -> Self

	func lock()

	func unlock()

	func with<R>(_ body: @Sendable () throws -> R) rethrows -> R where R : Sendable
}
