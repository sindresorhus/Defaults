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

extension Defaults.Bridge {
	public func serialize(_ value: Value?, usingCodable: Bool) -> Serializable? {
		serialize(value)
	}

	public func deserialize(_ object: Serializable?, usingCodable: Bool) -> Value? {
		deserialize(object)
	}
}

extension Data: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Date: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Bool: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Int: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension UInt: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Double: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Float: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension String: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension CGFloat: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Int8: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension UInt8: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Int16: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension UInt16: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Int32: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension UInt32: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension Int64: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension UInt64: Defaults.Serializable {
	public static let isNativelySupportedType = true
}

extension URL: Defaults.Serializable {
	public static var bridge: Defaults.TopLevelCodableBridge<URL> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: Codable {
	public static var bridge: Defaults.TopLevelCodableBridge<Self> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable & Codable {
	public static var bridge: Defaults.AmbiguousCodableBrigde<Self, Defaults.RawRepresentableBridge<Self>> { Defaults.AmbiguousCodableBrigde(bridge: Defaults.RawRepresentableBridge()) }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding {
	public static var bridge: Defaults.AmbiguousCodableBrigde<Self, Defaults.NSSecureCodingBridge<Self>> { Defaults.AmbiguousCodableBrigde(bridge: Defaults.NSSecureCodingBridge()) }
}

extension Defaults.Serializable where Self: RawRepresentable {
	public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Wrapped.isNativelySupportedType }
	public static var bridge: Defaults.OptionalBridge<Wrapped> { Defaults.OptionalBridge() }
}

extension Defaults.CollectionSerializable where Element: Defaults.Serializable {
	public static var isCollectionType: Bool { true }
	public static var bridge: Defaults.CollectionBridge<Self> { Defaults.CollectionBridge() }
}

extension Defaults.SetAlgebraSerializable where Element: Defaults.Serializable & Hashable {
	public static var bridge: Defaults.SetAlgebraBridge<Self> { Defaults.SetAlgebraBridge() }
}

extension Set: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.SetBridge<Element> { Defaults.SetBridge() }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Element.isNativelySupportedType }
	public static var bridge: Defaults.ArrayBridge<Element> { Defaults.ArrayBridge() }
}

extension Dictionary: Defaults.Serializable where Key: LosslessStringConvertible & Hashable, Value: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Value.isNativelySupportedType }
	public static var bridge: Defaults.DictionaryBridge<Key, Value> { Defaults.DictionaryBridge() }
}

#if os(macOS)
/// `NSColor` conforms to `NSSecureCoding`, so it goes to `NSSecureCodingBridge`.
extension NSColor: Defaults.Serializable {}
#else
/// `UIColor` conforms to `NSSecureCoding`, so it goes to `NSSecureCodingBridge`.
extension UIColor: Defaults.Serializable {}
#endif
