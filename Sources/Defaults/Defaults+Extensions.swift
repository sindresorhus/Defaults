import Foundation

extension Data: Defaults.NativelySupportedType {}
extension Date: Defaults.NativelySupportedType {}
extension Bool: Defaults.NativelySupportedType {}
extension Int: Defaults.NativelySupportedType {}
extension Double: Defaults.NativelySupportedType {}
extension Float: Defaults.NativelySupportedType {}
extension String: Defaults.NativelySupportedType {}
extension Int8: Defaults.NativelySupportedType {}
extension UInt8: Defaults.NativelySupportedType {}
extension Int16: Defaults.NativelySupportedType {}
extension UInt16: Defaults.NativelySupportedType {}
extension Int32: Defaults.NativelySupportedType {}
extension UInt32: Defaults.NativelySupportedType {}
extension Int64: Defaults.NativelySupportedType {}
extension UInt64: Defaults.NativelySupportedType {}

#if os(macOS)
extension CGFloat: Defaults.NativelySupportedType{}
#endif

extension Optional: Defaults.NativelySupportedType where Wrapped: Defaults.NativelySupportedType {}
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
	public static var bridge: Defaults.OptionalBridge<Wrapped.Bridge> { return Defaults.OptionalBridge(bridge: Wrapped.bridge) }
}

extension Array: Defaults.Serializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.ArrayBridge<Self, Element.Bridge> { return Defaults.ArrayBridge(bridge: Element.bridge) }
}

extension Dictionary: Defaults.Serializable where Key == String, Value: Defaults.Serializable {
	public static var bridge: Defaults.DictionaryBridge<Self, Value.Bridge> { return Defaults.DictionaryBridge(bridge: Value.bridge) }
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { return Defaults.NSSecureCodingBridge() }
}

