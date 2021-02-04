import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Defaults.Serializable {
	public static var isNativelySupportedType: Bool { false }
}

extension Data: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Date: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Bool: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Int: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension UInt: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Double: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Float: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension String: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension CGFloat: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Int8: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension UInt8: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Int16: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension UInt16: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Int32: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension UInt32: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension Int64: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension UInt64: Defaults.Serializable {
	public static let isNativelySupportedType = true
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

extension URL: Defaults.Serializable {
	public static let bridge = Defaults.URLBridge()
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

extension Defaults.Serializable where Self: Codable {
	public static var bridge: Defaults.TopLevelCodableBridge<Self> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable {
	public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable & Codable {
	public static var bridge: Defaults.RawRepresentableCodableBridge<Self> { Defaults.RawRepresentableCodableBridge() }
}

extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Wrapped.isNativelySupportedType }
	public static var bridge: Defaults.OptionalBridge<Wrapped> { Defaults.OptionalBridge() }
}
extension Optional: Defaults.NativeType where Wrapped: Defaults.NativeType {
	public typealias CodableForm = Wrapped.CodableForm
}

extension Defaults.CollectionSerializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.CollectionBridge<Self> { Defaults.CollectionBridge() }
}
extension Defaults.CollectionSerializable where Self: Defaults.NativeType, Element: Defaults.Serializable & Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}

extension Defaults.SetAlgebraSerializable where Element: Defaults.Serializable & Hashable {
	public static var bridge: Defaults.SetAlgebraBridge<Self> { Defaults.SetAlgebraBridge() }
}
extension Defaults.SetAlgebraSerializable where Self: Defaults.NativeType, Element: Defaults.Serializable & Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}

extension Set: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.SetBridge<Element> { Defaults.SetBridge() }
}
extension Set: Defaults.NativeType where Element: Defaults.Serializable & Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}


extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Element.isNativelySupportedType }
	public static var bridge: Defaults.ArrayBridge<Element> { Defaults.ArrayBridge() }
}
extension Array: Defaults.NativeType where Element: Defaults.Serializable & Defaults.NativeType {
	public typealias CodableForm = [Element.CodableForm]
}
extension Array: Defaults.CodableType where Element: Defaults.Serializable & Defaults.CodableType {
	public func toNative() -> [Element.NativeForm] {
		map { $0.toNative() }
	}
}

extension Dictionary: Defaults.Serializable where Key: LosslessStringConvertible & Hashable, Value: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Value.isNativelySupportedType }
	public static var bridge: Defaults.DictionaryBridge<Key, Value> { Defaults.DictionaryBridge() }
}
extension Dictionary: Defaults.NativeType where Key: LosslessStringConvertible & Hashable, Value: Defaults.Serializable & Defaults.NativeType {
	public typealias CodableForm = [String: Value.CodableForm]
}
extension Dictionary: Defaults.CodableType where Key == String, Value: Defaults.Serializable & Defaults.CodableType {
	public func toNative() -> [String: Value.NativeForm] {
		reduce(into: [String: Value.NativeForm]()) { memo, tuple in
			memo[tuple.key] = tuple.value.toNative()
		}
	}
}

#if os(macOS)
extension NSColor: Defaults.Serializable {}
#else
extension UIColor: Defaults.Serializable {}
#endif
