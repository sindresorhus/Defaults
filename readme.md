# Defaults

> Swifty and modern [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

Store key-value pairs persistently across launches of your app.

It uses `NSUserDefaults` underneath but exposes a type-safe facade with lots of nice conveniences.

It's used in production by apps like [Gifski](https://github.com/sindresorhus/Gifski), [Dato](https://sindresorhus.com/dato), [Lungo](https://sindresorhus.com/lungo), [Battery Indicator](https://sindresorhus.com/battery-indicator), and [HEIC Converter](https://sindresorhus.com/heic-converter).

For a real-world example, see my [Plash app](https://github.com/sindresorhus/Plash/blob/533dbc888d8ba3bd9581e60320af282a22c53f85/Plash/Constants.swift#L9-L18).

## Highlights

- **Strongly typed:** You declare the type and default value upfront.
- **Codable support:** You can store any [Codable](https://developer.apple.com/documentation/swift/codable) value, like an enum.
- **NSSecureCoding support:** You can store any [NSSecureCoding](https://developer.apple.com/documentation/foundation/nssecurecoding) value.
- **SwiftUI:** Property wrapper that updates the view when the `UserDefaults` value changes.
- **Publishers:** Combine publishers built-in.
- **Observation:** Observe changes to keys.
- **Debuggable:** The data is stored as JSON-serialized values.
- **Customizable:** You can create your own type.

## Compatibility

- macOS 10.12+
- iOS 10+
- tvOS 10+
- watchOS 3+

## Migration Guides

#### [From v4 to v5](./migration.md)

## Install

#### Swift Package Manager

Add `https://github.com/sindresorhus/Defaults` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

#### Carthage

```
github "sindresorhus/Defaults"
```

#### CocoaPods

```ruby
pod 'Defaults'
```

## Usage

You declare the defaults keys upfront with type and default value.

```swift
import Cocoa
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

Defaults[.quality] += 0.1
//=> 0.6

Defaults[.quality] = "🦄"
//=> [Cannot assign value of type 'String' to type 'Double']
```

You can also declare optional keys for when you don't want to declare a default value upfront:

```swift
extension Defaults.Keys {
	static let name = Key<Double?>("name")
}

if let name = Defaults[.name] {
	print(name)
}
```

The default value is then `nil`.

---

### Enum example

```swift
enum DurationKeys: String {
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

### Use keys directly

You are not required to attach keys to `Defaults.Keys`.

```swift
let isUnicorn = Defaults.Key<Bool>("isUnicorn", default: true)

Defaults[isUnicorn]
//=> true
```

### SwiftUI support

You can use the `@Default` property wrapper to get/set a `Defaults` item and also have the view be updated when the value changes. This is similar to `@State`.

```swift
extension Defaults.Keys {
	static let hasUnicorn = Key<Bool>("hasUnicorn", default: false)
}

struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn

	var body: some View {
		Text("Has Unicorn: \(hasUnicorn)")
		Toggle("Toggle Unicorn", isOn: $hasUnicorn)
	}
}
```

Note that it's `@Default`, not `@Defaults`.

You cannot use `@Default` in an `ObservableObject`. It's meant to be used in a `View`.

### Observe changes to a key

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
}

let observer = Defaults.observe(.isUnicornMode) { change in
	// Initial event
	print(change.oldValue)
	//=> false
	print(change.newValue)
	//=> false

	// First actual event
	print(change.oldValue)
	//=> false
	print(change.newValue)
	//=> true
}

Defaults[.isUnicornMode] = true
```

In contrast to the native `UserDefaults` key observation, here you receive a strongly-typed change object.

There is also an observation API using the [Combine](https://developer.apple.com/documentation/combine) framework, exposing a [Publisher](https://developer.apple.com/documentation/combine/publisher) for key changes:

```swift
let publisher = Defaults.publisher(.isUnicornMode)

let cancellable = publisher.sink { change in
	// Initial event
	print(change.oldValue)
	//=> false
	print(change.newValue)
	//=> false

	// First actual event
	print(change.oldValue)
	//=> false
	print(change.newValue)
	//=> true
}

Defaults[.isUnicornMode] = true

// To invalidate the observation.
cancellable.cancel()
```

### Invalidate observations automatically

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
}

final class Foo {
	init() {
		Defaults.observe(.isUnicornMode) { change in
			print(change.oldValue)
			print(change.newValue)
		}.tieToLifetime(of: self)
	}
}

Defaults[.isUnicornMode] = true
```

The observation will be valid until `self` is deinitialized.

### Reset keys to their default values

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
}

Defaults[.isUnicornMode] = true
//=> true

Defaults.reset(.isUnicornMode)

Defaults[.isUnicornMode]
//=> false
```

This works for a `Key` with an optional too, which will be reset back to `nil`.

### Control propagation of change events

Changes made within the `Defaults.withoutPropagation` closure will not be propagated to observation callbacks (`Defaults.observe()` or `Defaults.publisher()`), and therefore could prevent infinite recursion.

```swift
let observer = Defaults.observe(keys: .key1, .key2) {
		// …

		Defaults.withoutPropagation {
			// Update `.key1` without propagating the change to listeners.
			Defaults[.key1] = 11
		}

		// This will be propagated.
		Defaults[.someKey] = true
	}
```

### It's just `UserDefaults` with sugar

This works too:

```swift
extension Defaults.Keys {
	static let isUnicorn = Key<Bool>("isUnicorn", default: true)
}

UserDefaults.standard[.isUnicorn]
//=> true
```

### Shared `UserDefaults`

```swift
let extensionDefaults = UserDefaults(suiteName: "com.unicorn.app")!

extension Defaults.Keys {
	static let isUnicorn = Key<Bool>("isUnicorn", default: true, suite: extensionDefaults)
}

Defaults[.isUnicorn]
//=> true

// Or

extensionDefaults[.isUnicorn]
//=> true
```

### Default values are registered with `UserDefaults`

When you create a `Defaults.Key`, it automatically registers the `default` value with normal `UserDefaults`. This means you can make use of the default value in, for example, bindings in Interface Builder.

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: true)
}

print(UserDefaults.standard.bool(forKey: Defaults.Keys.isUnicornMode.name))
//=> true
```

### Custom types

Although `Defaults` already support many types internal, there might have some situations that you want to use your own type.
The guide below will show you how to create your own custom type.

1. Create your own custom type
```swift
struct User {
	var name: String
	var age: String
}
```

2. Create a bridge which protocol conform to `Defaults.Bridge`
```swift
struct UserBridge: Defaults.Bridge {
	typealias Value = User
	typealias Serializable = [String: String]

	public func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["username": value.username, "password": value.password]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
			let username = object["username"],
			let password = object["password"]
		else {
			return nil
		}

		return User(username: username, password: password)
	}
}
``` 

3. Let your own custom type protocol conform to `Defaults.Serializable` and its static bridge should be the bridge we created above.
```swift
struct User: Defaults.Serializable {
	var name: String
	var age: String

	static let bridge = UserBridge()
}
```

## API

### `Defaults`

#### `Defaults.Keys`

Type: `class`

Stores the keys.

#### `Defaults.Key` *(alias `Defaults.Keys.Key`)*

```swift
Defaults.Key<T>(_ key: String, default: T, suite: UserDefaults = .standard)
```

Type: `class`

Create a key with a default value.

The default value is written to the actual `UserDefaults` and can be used elsewhere. For example, with a Interface Builder binding.

#### `Defaults.Serializable`

```swift
public protocol DefaultsSerializable {
	static var bridge: Defaults.Bridge { get }
}
```

Type: `protocol`

A protocol which can do serialization and de-serialization easily.

It should have a static variable `bridge` and its protocol should conform to `Defaults.Bridge`.

#### `Defaults.CollectionSerializable`

```swift
public protocol DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	init(_ elements: [Element])
}
```

Type: `protocol`

A `Collection` which can store into the `UserDefaults`.

It should have an initializer `init(_ elements: [Element])` to let `Defaults` do the de-serialization.

#### `Defaults.SetAlgebraSerializable`

```swift
public protocol DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	func toArray() -> [Element]
}
```

Type: `protocol`

A `SetAlgebra` which can store into the `UserDefaults`.

It should have a function `func toArray() -> [Element]` to let `Defaults` do the serialization.

#### `Defaults.Bridge`

```swift
public protocol DefaultsBridge {
	associatedtype Value
	associatedtype Serializable
	func serialize(_ value: Value?) -> Serializable?
	func deserialize(_ object: Serializable?) -> Value?
}
```

Type: `protocol`

A Bridge can do the serialization and de-serialization.

Have two associate types `Value` and `Serializable`.

`Value` is the type user want to use it.

`Serializable` is the type stored in `UserDefaults`.

`serialize` will be executed before storing to the `UserDefaults` .

`deserialize` will be executed after retrieving its value from the `UserDefaults`.

#### `Defaults.reset(keys…)`

Type: `func`

Reset the given keys back to their default values.

You can specify up to 10 keys. If you need to specify more, call this method multiple times.

You can also specify string keys, which can be useful if you need to store some keys in a collection, as it's not possible to store `Defaults.Key` in a collection because it's generic.

#### `Defaults.observe`

```swift
Defaults.observe<T: Codable>(
	_ key: Defaults.Key<T>,
	options: ObservationOptions = [.initial],
	handler: @escaping (KeyChange<T>) -> Void
) -> Defaults.Observation
```

Type: `func`

Observe changes to a key or an optional key.

By default, it will also trigger an initial event on creation. This can be useful for setting default values on controls. You can override this behavior with the `options` argument.

#### `Defaults.observe(keys: keys..., options:)`

Type: `func`

Observe multiple keys of any type, but without any information about the changes.

Options are the same as in `.observe(…)` for a single key.

#### `Defaults.publisher(_ key:, options:)`

```swift
Defaults.publisher<T: Codable>(
	_ key: Defaults.Key<T>,
	options: ObservationOptions = [.initial]
) -> AnyPublisher<KeyChange<T>, Never>
```

Type: `func`

Observation API using [Publisher](https://developer.apple.com/documentation/combine/publisher) from the [Combine](https://developer.apple.com/documentation/combine) framework.

Available on macOS 10.15+, iOS 13.0+, tvOS 13.0+, and watchOS 6.0+.

#### `Defaults.publisher(keys: keys…, options:)`

Type: `func`

[Combine](https://developer.apple.com/documentation/combine) observation API for multiple key observation, but without specific information about changes.

Available on macOS 10.15+, iOS 13.0+, tvOS 13.0+, and watchOS 6.0+.

#### `Defaults.removeAll`

```swift
Defaults.removeAll(suite: UserDefaults = .standard)
```

Type: `func`

Remove all entries from the given `UserDefaults` suite.

### `Defaults.Observation`

Type: `protocol`

Represents an observation of a defaults key.

#### `Defaults.Observation#invalidate`

```swift
Defaults.Observation#invalidate()
```

Type: `func`

Invalidate the observation.

#### `Defaults.Observation#tieToLifetime`

```swift
@discardableResult
Defaults.Observation#tieToLifetime(of weaklyHeldObject: AnyObject) -> Self
```

Type: `func`

Keep the observation alive for as long as, and no longer than, another object exists.

When `weaklyHeldObject` is deinitialized, the observation is invalidated automatically.

#### `Defaults.Observation.removeLifetimeTie`

```swift
Defaults.Observation#removeLifetimeTie()
```

Type: `func`

Break the lifetime tie created by `tieToLifetime(of:)`, if one exists.

The effects of any call to `tieToLifetime(of:)` are reversed. Note however that if the tied-to object has already died, then the observation is already invalid and this method has no logical effect.

#### `Defaults.withoutPropagation(_ closure:)`

Execute the closure without triggering change events.

Any `Defaults` key changes made within the closure will not propagate to `Defaults` event listeners (`Defaults.observe()` and `Defaults.publisher()`). This can be useful to prevent infinite recursion when you want to change a key in the callback listening to changes for the same key.

### `@Default(_ key:)`

Get/set a `Defaults` item and also have the view be updated when the value changes.

### `Defaults.migration(keys..., to: Version)`

```swift
Defaults.migration<T: Defaults.Serializable & Codable>(keys..., to: Version)
Defaults.migration<T: Defaults.NativeType>(keys..., to: Version)
```

Type: `func`

Migrate the given keys to the specific version.

You can specify up to 10 keys. If you need to specify more, call this method multiple times.

#### `Defaults.NativeType`

```swift
protocol DefaultsNativeType: Defaults.Serializable {
	associatedtype CodableForm: Defaults.CodableType
}
```

Type: `protocol`

Represents the type after migration.

It should have a associated type name `CodableForm` which protocol conform to `Codable`.

#### `Defaults.CodableType`

```swift
protocol DefaultsCodableType: Codable {
	associatedtype NativeForm: Defaults.NativeType
	func toNative() -> NativeForm
}
```

Type: `protocol`

Represents the type before migration.

It should have an associated type name `NativeForm` which is the type we want it to store in `UserDefaults`.

And it also have a `toNative()` function to convert itself into `NativeForm`.

## FAQ

### How can I store a dictionary of arbitrary values?

You cannot store `[String: Any]` directly as it cannot conform to `Codable`. However, you can use the [`AnyCodable`](https://github.com/Flight-School/AnyCodable) package to work around this `Codable` limitation:

```swift
import AnyCodable

extension AnyCodable: Defaults.Serializable {}

extension Defaults.Keys {
	static let magic = Key<[String: AnyCodable]>("magic", default: [:])
}

// …

Defaults[.magic]["unicorn"] = "🦄"

if let value = Defaults[.magic]["unicorn"]?.value {
	print(value)
	//=> "🦄"
}

Defaults[.magic]["number"] = 3
Defaults[.magic]["boolean"] = true
```

### How is this different from [`SwiftyUserDefaults`](https://github.com/radex/SwiftyUserDefaults)?

It's inspired by that package and other solutions. The main difference is that this module doesn't hardcode the default values and comes with Codable support.

## Maintainers

- [Sindre Sorhus](https://github.com/sindresorhus)
- [Kacper Rączy](https://github.com/fredyshox)

## Related

- [Preferences](https://github.com/sindresorhus/Preferences) - Add a preferences window to your macOS app
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Add user-customizable global keyboard shortcuts to your macOS app
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [DockProgress](https://github.com/sindresorhus/DockProgress) - Show progress in your app's Dock icon
- [Gifski](https://github.com/sindresorhus/Gifski) - Convert videos to high-quality GIFs on your Mac
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift)
