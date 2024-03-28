# ``Defaults``

Store key-value pairs persistently across launches of your app.

It uses [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) underneath but exposes a type-safe facade with lots of nice conveniences.

## Usage

You declare the defaults keys upfront with a type and default value.

```swift
import Defaults

extension Defaults.Keys {
	static let quality = Key<Double>("quality", default: 0.8)
	//            ^            ^         ^                ^
	//           Key          Type   UserDefaults name   Default value
}
```

You can then access it as a subscript on the `Defaults` global:

```swift
Defaults[.quality]
//=> 0.8

Defaults[.quality] = 0.5
//=> 0.5
```

[Learn More](https://github.com/sindresorhus/Defaults#usage)

### Tip

If you don't want to import this package in every file you use it, add the below to a file in your app. You can then use `Defaults` and `@Default` from anywhere without an import.

```swift
import Defaults

typealias Defaults = _Defaults
typealias Default = _Default
```

## Topics

### Essentials

- ``Defaults/subscript(_:)``
- ``Defaults/Key``
- ``Defaults/Serializable``

### Methods

- ``Defaults/updates(_:initial:)-9eh8``
- ``Defaults/updates(_:initial:)-1mqkb``
- ``Defaults/reset(_:)-7jv5v``
- ``Defaults/reset(_:)-7es1e``
- ``Defaults/removeAll(suite:)``

### SwiftUI

- ``Default``
- ``Defaults/Toggle``

### Force Type Resolution

- ``Defaults/PreferRawRepresentable``
- ``Defaults/PreferNSSecureCoding``

### iCloud

- ``Defaults/iCloud``
