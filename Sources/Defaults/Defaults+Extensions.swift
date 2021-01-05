import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Data: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Date: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Bool: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Int: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Double: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Float: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension String: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension CGFloat: Defaults.Serializable{
	public static let isNativelySupportType = true
}
extension Int8: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension UInt8: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Int16: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension UInt16: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Int32: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension UInt32: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension Int64: Defaults.Serializable {
	public static let isNativelySupportType = true
}
extension UInt64: Defaults.Serializable {
	public static let isNativelySupportType = true
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
	public static var isNativelySupportType: Bool { Wrapped.isNativelySupportType }
	public static var bridge: Defaults.OptionalBridge<Wrapped> { return Defaults.OptionalBridge() }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var isNativelySupportType: Bool { Element.isNativelySupportType }
	public static var bridge: Defaults.ArrayBridge<Element> { return Defaults.ArrayBridge() }
}

extension Dictionary: Defaults.Serializable where Key == String, Value: Defaults.Serializable {
	public static var isNativelySupportType: Bool { Value.isNativelySupportType }
	public static var bridge: Defaults.DictionaryBridge<Value> { return Defaults.DictionaryBridge() }
}

#if os(macOS)
extension NSColor: Defaults.Serializable {}
#else
extension UIColor: Defaults.Serializable {}
#endif
