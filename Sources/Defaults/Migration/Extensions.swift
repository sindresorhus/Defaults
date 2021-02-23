import Foundation
import CoreGraphics

extension Defaults {
	public typealias NativeType = DefaultsNativeType
	public typealias CodableType = DefaultsCodableType
}

extension Data: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Data: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Date: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Date: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Bool: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Bool: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Int: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Int: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension UInt: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension UInt: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Double: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Double: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Float: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Float: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension String: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension String: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension CGFloat: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension CGFloat: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Int8: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Int8: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension UInt8: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension UInt8: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Int16: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Int16: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension UInt16: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension UInt16: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Int32: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Int32: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension UInt32: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension UInt32: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension Int64: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension Int64: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension UInt64: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension UInt64: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
}

extension URL: Defaults.NativeType {
	public typealias CodableForm = Self
}
extension URL: Defaults.CodableType {
	public typealias NativeForm = Self

	public func toNative() -> Self {
		self
	}
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