import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
extension Double: Defaults.Serializable {
	public static let isNativelySupportedType = true
}
extension Float: Defaults.Serializable {
	public static let isNativelySupportedType = true
}
extension String: Defaults.Serializable {
	public static let isNativelySupportedType = true
}
extension CGFloat: Defaults.Serializable{
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
	public static var bridge: Defaults.TopLevelCodableBridge<Self> { return Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable {
	public static var bridge: Defaults.RawRepresentableBridge<Self> { return Defaults.RawRepresentableBridge() }
}

extension Defaults.Serializable where Self: RawRepresentable & Codable {
	public static var bridge: Defaults.RawRepresentableCodableBridge<Self> { return Defaults.RawRepresentableCodableBridge() }
}

extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { return Defaults.NSSecureCodingBridge() }
}

extension Set: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.SetBridge<Element> { return Defaults.SetBridge() }
}

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Wrapped.isNativelySupportedType }
	public static var bridge: Defaults.OptionalBridge<Wrapped> { return Defaults.OptionalBridge() }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Element.isNativelySupportedType }
	public static var bridge: Defaults.ArrayBridge<Element> { return Defaults.ArrayBridge() }
}

extension Dictionary: Defaults.Serializable where Key == String, Value: Defaults.Serializable {
	public static var isNativelySupportedType: Bool { Value.isNativelySupportedType }
	public static var bridge: Defaults.DictionaryBridge<Value> { return Defaults.DictionaryBridge() }
}

#if os(macOS)
extension NSColor: Defaults.Serializable {}
#else
extension UIColor: Defaults.Serializable {}
#endif
