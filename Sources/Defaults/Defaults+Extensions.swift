import Foundation

extension Data: Defaults.Serializable {}
extension Date: Defaults.Serializable {}
extension Bool: Defaults.Serializable {}
extension Int: Defaults.Serializable {}
extension Double: Defaults.Serializable {}
extension Float: Defaults.Serializable {}
extension String: Defaults.Serializable {}
extension CGFloat: Defaults.Serializable{}
extension Int8: Defaults.Serializable {}
extension UInt8: Defaults.Serializable {}
extension Int16: Defaults.Serializable {}
extension UInt16: Defaults.Serializable {}
extension Int32: Defaults.Serializable {}
extension UInt32: Defaults.Serializable {}
extension Int64: Defaults.Serializable {}
extension UInt64: Defaults.Serializable {}

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

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { return Defaults.NSSecureCodingBridge() }
}

extension Optional: Defaults.Serializable where Wrapped: Defaults.Serializable {
	public static var bridge: Defaults.OptionalBridge<Wrapped.Bridge> { return Defaults.OptionalBridge(bridge: Wrapped.bridge) }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.ArrayBridge<Self, Element.Bridge> { return Defaults.ArrayBridge(bridge: Element.bridge) }
}

extension Dictionary: Defaults.Serializable where Key == String, Value: Defaults.Serializable {
	public static var bridge: Defaults.DictionaryBridge<Self, Value.Bridge> { return Defaults.DictionaryBridge(bridge: Value.bridge) }
}

extension Optional: Defaults.NativelySupportedType where Wrapped: Defaults.NativelySupportedType {
	public typealias Property = Wrapped
}

extension Array: Defaults.NativelySupportedType where Element: Defaults.NativelySupportedType {
	public typealias Property = Element
}

extension Dictionary: Defaults.NativelySupportedType where Key == String, Value: Defaults.NativelySupportedType {
	public typealias Property = Value
}
