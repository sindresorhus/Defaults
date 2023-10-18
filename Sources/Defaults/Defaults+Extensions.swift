import SwiftUI
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
	public static let bridge = Defaults.URLBridge()
}

extension Defaults.Serializable where Self: Codable {
	public static var bridge: Defaults.TopLevelCodableBridge<Self> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding & NSObject {
	public static var bridge: Defaults.CodableNSSecureCodingBridge<Self> { Defaults.CodableNSSecureCodingBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding & NSObject & Defaults.PreferNSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Defaults.Serializable where Self: Codable & RawRepresentable {
	public static var bridge: Defaults.RawRepresentableCodableBridge<Self> { Defaults.RawRepresentableCodableBridge() }
}

extension Defaults.Serializable where Self: Codable & RawRepresentable & Defaults.PreferRawRepresentable {
	public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable {
	public static var bridge: Defaults.RawRepresentableBridge<Self> { Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: NSSecureCoding & NSObject {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Wrapped.isNativelySupportedType }
	public static var bridge: Defaults.OptionalBridge<Wrapped> { Defaults.OptionalBridge() }
}

extension Defaults.CollectionSerializable where Element: Defaults.Serializable {
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
	public static var isNativelySupportedType: Bool { (Key.self is String.Type) && Value.isNativelySupportedType }
	public static var bridge: Defaults.DictionaryBridge<Key, Value> { Defaults.DictionaryBridge() }
}

extension UUID: Defaults.Serializable {
	public static let bridge = Defaults.UUIDBridge()
}

extension Color: Defaults.Serializable {
	public static let bridge = Defaults.ColorBridge()
}

extension Range: Defaults.RangeSerializable where Bound: Defaults.Serializable {
	public static var bridge: Defaults.RangeBridge<Range> { Defaults.RangeBridge() }
}

extension ClosedRange: Defaults.RangeSerializable where Bound: Defaults.Serializable {
	public static var bridge: Defaults.RangeBridge<ClosedRange> { Defaults.RangeBridge() }
}

#if os(macOS)
/**
`NSColor` conforms to `NSSecureCoding`, so it goes to `NSSecureCodingBridge`.
*/
extension NSColor: Defaults.Serializable {}
#else
/**
`UIColor` conforms to `NSSecureCoding`, so it goes to `NSSecureCodingBridge`.
*/
extension UIColor: Defaults.Serializable {}
#endif
