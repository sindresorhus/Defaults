import Foundation
import CoreGraphics

extension Defaults {
	public typealias NativeType = DefaultsNativeType
	public typealias CodableType = DefaultsCodableType
}

extension Optional: Defaults.NativeType where Wrapped: Defaults.NativeType {
	public typealias CodableForm = Wrapped.CodableForm
}

extension Defaults.CollectionSerializable where Self: Defaults.NativeType, Element: Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}

extension Defaults.SetAlgebraSerializable where Self: Defaults.NativeType, Element: Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}

extension Set: Defaults.NativeType where Element: Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}

extension Array: Defaults.NativeType where Element: Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}
extension Array: Defaults.CodableType where Element: Defaults.CodableType {
	public func toNative() -> [Element.NativeForm] {
		map { $0.toNative() }
	}
}

extension Dictionary: Defaults.NativeType where Key: LosslessStringConvertible & Hashable, Value: Defaults.NativeType {
	public typealias CodableForm = [String: Value.CodableForm]
}
extension Dictionary: Defaults.CodableType where Key == String, Value: Defaults.CodableType {
	public func toNative() -> [String: Value.NativeForm] {
		reduce(into: [String: Value.NativeForm]()) { memo, tuple in
			memo[tuple.key] = tuple.value.toNative()
		}
	}
}


extension Defaults {
	public static func migration<Value: Defaults.Serializable & Codable>(_ keys: Key<Value>...) {
		migration(keys)
	}

	public static func migration<Value: Defaults.NativeType>(_ keys: Key<Value>...) {
		migration(keys)
	}

	/**
	Migration the given key's value from json string to `Value`.
	```
	extension Defaults.Keys {
		static let array = Key<Set<String>?>("array")
	}
	let text = "[\"a\", \"b\", \"c\"]"
	UserDefaults.standard.set(text, forKey: "array")

	UserDefaults.standard.string(forKey: keyName)
	//=> ["a","b","c"]

	Defaults.migration(.array)
	UserDefaults.standard.array(forKey: keyName)
	//=> [a, b, c, d]
	```
	*/
	public static func migration<Value: Defaults.Serializable & Codable>(_ keys: [Key<Value>]) {
		for key in keys {
			let suite = key.suite
			suite.migration(forKey: key.name, of: Value.self)
		}
	}

	public static func migration<Value: Defaults.NativeType>(_ keys: [Key<Value>]) {
		for key in keys {
			let suite = key.suite
			suite.migration(forKey: key.name, of: Value.self)
		}
	}
}
