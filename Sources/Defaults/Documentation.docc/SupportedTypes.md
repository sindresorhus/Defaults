# Supported Types

Learn about the types that Defaults supports out of the box.

## Overview

Defaults supports a wide range of types natively, including primitives, dates, URLs, colors, and even `Codable` and `NSSecureCoding` types.

## Primitive Types

Defaults supports all standard Swift number types and basic types:

- `Int`, `Int8`, `Int16`, `Int32`, `Int64`
- `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Double`
- `CGFloat`
- `Float`
- `String`
- `Bool`

## Foundation Types

- `Date`
- `Data`
- `URL`
- `UUID`

## Ranges

- `Range`
- `ClosedRange`

## Protocol-Based Types

- `Codable` - Any type conforming to `Codable`
- `NSSecureCoding` - Any type conforming to `NSSecureCoding`

If a type conforms to both `NSSecureCoding` and `Codable`, then `Codable` will be used for the serialization by default. See <doc:AdvancedUsage#Select-a-Preferred-Bridge> to learn how to override this behavior.

## Color Types

Defaults supports color types from SwiftUI, UIKit, and AppKit:

- `Color` (SwiftUI)
- `Color.Resolved` (SwiftUI)
- `NSColor` (AppKit)
- `UIColor` (UIKit)

> Important: You cannot use `Color.accentColor` as it [cannot be serialized](https://github.com/sindresorhus/Defaults/issues/139).

## Font Descriptor Types

- `NSFontDescriptor` (AppKit)
- `UIFontDescriptor` (UIKit)

## Collections

Defaults supports the above types wrapped in collections, and even nested collections:

- `Array`
- `Set`
- `Dictionary`

For example, you can store complex nested types like `[[String: Set<UUID>]]`.

## Enum Example

Enums with raw values that conform to supported types work automatically:

```swift
enum DurationKeys: String, Defaults.Serializable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let defaultDuration = Key<DurationKeys>("defaultDuration", default: .oneHour)
}

Defaults[.defaultDuration].rawValue
//=> "1 Hour"
```

This works as long as the raw value of the enum is any of the supported types.

## Codable Example

Any type conforming to `Codable` can be stored:

```swift
struct User: Codable, Defaults.Serializable {
	let name: String
	let age: String
}

extension Defaults.Keys {
	static let user = Key<User>("user", default: .init(name: "Hello", age: "24"))
}

Defaults[.user].name
//=> "Hello"
```

## Custom Types

You can easily add support for any custom type. See <doc:AdvancedUsage> for how to add support for your own types.

## Topics

### Making Types Compatible

- ``Defaults/Serializable``
- ``Defaults/Bridge``

### Collections

- ``Defaults/CollectionSerializable``
- ``Defaults/SetAlgebraSerializable``

### Type Erasure

- ``Defaults/AnySerializable``

### Disambiguation

- ``Defaults/PreferRawRepresentable``
- ``Defaults/PreferNSSecureCoding``
