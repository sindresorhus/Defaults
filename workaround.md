## Workaround For Xcode 13.3

When using `Defaults` with Xcode 13.3 the compiler might complain about `Type 'YourType' does not conform to protocol 'DefaultsSerializable'`.  

Try the step below:

1. Create `Defaults+Workaround.swift` in the module which is using `Defaults`.
2. Copy the codes below into `Defaults+Workaround.swift`

```swift
import Defaults
import Foundation

extension Defaults.Serializable where Self: Codable {
	public static var bridge: Defaults.TopLevelCodableBridge<Self> { Defaults.TopLevelCodableBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding {
	public static var bridge: Defaults.CodableNSSecureCodingBridge<Self> { Defaults.CodableNSSecureCodingBridge() }
}

extension Defaults.Serializable where Self: Codable & NSSecureCoding & Defaults.PreferNSSecureCoding {
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
extension Defaults.Serializable where Self: NSSecureCoding {
	public static var bridge: Defaults.NSSecureCodingBridge<Self> { Defaults.NSSecureCodingBridge() }
}

extension Defaults.CollectionSerializable where Element: Defaults.Serializable {
	public static var bridge: Defaults.CollectionBridge<Self> { Defaults.CollectionBridge() }
}

extension Defaults.SetAlgebraSerializable where Element: Defaults.Serializable & Hashable {
	public static var bridge: Defaults.SetAlgebraBridge<Self> { Defaults.SetAlgebraBridge() }
}
```

This issue is caused by swift compiler. After [SR-15807](https://bugs.swift.org/browse/SR-15807) is fixed this workaround might not be needed.