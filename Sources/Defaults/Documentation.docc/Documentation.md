# ``Defaults``

Store key-value pairs persistently across launches of your app.

## Overview

Defaults is a Swifty and modern wrapper for [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults). It provides a type-safe facade with lots of nice conveniences and makes it easier to work with persistent storage.

### Features

- **Strongly Typed**: Declare types and default values upfront with full compiler support
- **SwiftUI Support**: Property wrappers that automatically update views when values change
- **Codable Support**: Store any [`Codable`](https://developer.apple.com/documentation/swift/codable) value, like enums and structs
- **NSSecureCoding Support**: Store any [`NSSecureCoding`](https://developer.apple.com/documentation/foundation/nssecurecoding) value
- **Observation**: Observe changes to keys with async/await or callbacks
- **Debuggable**: Data is stored as JSON-serialized values for easy inspection
- **Customizable**: Add support for your own custom types easily
- **iCloud Support**: Automatically synchronize data between devices

### Quick Example

Declare keys with types and default values:

```swift
import Defaults

extension Defaults.Keys {
	static let quality = Key<Double>("quality", default: 0.8)
}
```

Access values with a type-safe subscript:

```swift
Defaults[.quality]
//=> 0.8

Defaults[.quality] = 0.5
//=> 0.5
```

Use in SwiftUI with automatic view updates:

```swift
struct ContentView: View {
	@Default(.quality) var quality

	var body: some View {
		Slider(value: $quality, in: 0...1)
	}
}
```

## Topics

### Learn the Basics

- <doc:Introduction>
- <doc:SupportedTypes>

### Customize Storage

- <doc:AdvancedUsage>
- <doc:ExternalStorage>
- ``Defaults/Serializable``
- ``Defaults/Bridge``
- ``Defaults/CollectionSerializable``
- ``Defaults/SetAlgebraSerializable``
- ``Defaults/AnySerializable``
- ``Defaults/PreferRawRepresentable``
- ``Defaults/PreferNSSecureCoding``

### Build Interfaces

- <doc:SwiftUIIntegration>
- ``Default``
- ``Defaults/Toggle``

### Monitor Changes

- ``Defaults/updates(_:initial:)-88orv``
- ``Defaults/updates(_:initial:)-l03o``
- ``Defaults/updates(_:initial:)-1mqkb``
- ``Defaults/withoutPropagation(_:)``

### Manage Values

- ``Defaults/reset(_:)-7jv5v``
- ``Defaults/reset(_:)-7es1e``
- ``Defaults/removeAll(suite:)``

### Core API

- ``Defaults/subscript(_:)``
- ``Defaults/Keys``
- ``Defaults/Key``

### Sync Across Devices

- ``Defaults/iCloud``

### Help

- <doc:FAQ>
