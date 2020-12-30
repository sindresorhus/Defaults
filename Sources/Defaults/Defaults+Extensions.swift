import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#else
import UIKit
#endif
extension Data: Defaults.NativelySupportedType {}
extension Date: Defaults.NativelySupportedType {}
extension Bool: Defaults.NativelySupportedType {}
extension Int: Defaults.NativelySupportedType {}
extension Double: Defaults.NativelySupportedType {}
extension Float: Defaults.NativelySupportedType {}
extension String: Defaults.NativelySupportedType {}
extension CGFloat: Defaults.NativelySupportedType{}
extension Int8: Defaults.NativelySupportedType {}
extension UInt8: Defaults.NativelySupportedType {}
extension Int16: Defaults.NativelySupportedType {}
extension UInt16: Defaults.NativelySupportedType {}
extension Int32: Defaults.NativelySupportedType {}
extension UInt32: Defaults.NativelySupportedType {}
extension Int64: Defaults.NativelySupportedType {}
extension UInt64: Defaults.NativelySupportedType {}

extension Optional: Defaults.NativelySupportedType where Wrapped: Defaults.NativelySupportedType {}
extension Set: Defaults.NativelySupportedType where Element: Defaults.NativelySupportedType {}
extension Array: Defaults.NativelySupportedType where Element: Defaults.NativelySupportedType {}
extension Dictionary: Defaults.NativelySupportedType where Key == String, Value: Defaults.NativelySupportedType {}

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

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var bridge: Defaults.OptionalBridge<Wrapped> { return Defaults.OptionalBridge() }
}

extension Set: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.SetBridge<Element> { return Defaults.SetBridge() }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.ArrayBridge<Element> { return Defaults.ArrayBridge() }
}

extension Dictionary: Defaults.Serializable where Key == String, Value: Defaults.Serializable {
	public static var bridge: Defaults.DictionaryBridge<Value> { return Defaults.DictionaryBridge() }
}

extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { return Defaults.NSSecureCodingBridge() }
}

#if os(macOS)
extension NSColor: Defaults.Serializable {}
#else
extension UIColor: Defaults.Serializable {}
#endif
