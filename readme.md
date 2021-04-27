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
- **Customizable:** You can serialize and deserialize your own type in your own way.

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

## Support types

|    Single Value    |        Array         |            Set            | Dictionary<T: LosslessStringConvertible> |
| :----------------: | :------------------: | :-----------------------: | :--------------------------------------: |
| `Int(8/16/32/64)`  | `[Int(8/16/32/64)]`  |  `Set<Int(8/16/32/64)>`   |          `[T: Int(8/16/32/64)]`          |
| `UInt(8/16/32/64)` | `[UInt(8/16/32/64)]` |  `Set<UInt(8/16/32/64)>`  |         `[T: UInt(8/16/32/64)]`          |
|      `Double`      |      `[Double]`      |       `Set<Double>`       |              `[T: Double]`               |
|      `Float`       |      `[Float]`       |       `Set<Float>`        |               `[T: Float]`               |
|      `String`      |      `[String]`      |       `Set<String>`       |              `[T: String]`               |
|     `CGFloat`      |     `[CGFloat]`      |      `Set<CGFloat>`       |              `[T: CGFloat]`              |
|       `Bool`       |       `[Bool]`       |        `Set<Bool>`        |               `[T: Bool]`                |
|       `Date`       |       `[Date]`       |        `Set<Date>`        |               `[T: Date]`                |
|       `Data`       |       `[Data]`       |        `Set<Data>`        |               `[T: Data]`                |
|       `URL`        |       `[URL]`        |        `Set<URL>`         |                `[T: URL]`                |
| `NSColor` (macOS)  | `[NSColor]` (macOS)  |  `Set<NSColor>` (macOS)   |          `[T: NSColor]` (macOS)          |
|  `UIColor` (iOS)   |  `[UIColor]` (iOS)   |      `Set<UIColor>`       |           `[T: UIColor]` (iOS)           |

The list above only show the type that does not need further more configuration.
For more types, see [Enum Example](#enum-example), [Codable Example](#codable-example) or [Advanced Usage](#advanced-usage).

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

### Codable Example

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

## Advanced Usage

### Serialization of custom types

Although `Defaults` already support many types internal, there might have some situations where you want to use your own type.
The guide below will show you how to make your own custom type works with `Defaults`.

1. Create your own custom type.

```swift
struct User {
	let name: String
	let age: String
}
```

2. Create a bridge which protocol conforms to `Defaults.Bridge`.

```swift
struct UserBridge: Defaults.Bridge {
	typealias Value = User
	typealias Serializable = [String: String]

	public func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["name": value.name, "age": value.age]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object = object,
			let name = object["name"],
			let age = object["age"]
		else {
			return nil
		}

		return User(name: name, age: age)
	}
}
```

3. Create an extension of `User`, let its protocol conforms to `Defaults.Serializable` and its static bridge should be the bridge we created above.

```swift
struct User {
	let name: String
	let age: String
}

extension User: Defaults.Serializable {
	static let bridge = UserBridge()
}
```

4. Create some keys and enjoy it.

```swift
extension Defaults.Keys {
	static let user = Defaults.Key<User>("user", default: User(name: "Hello", age: "24"))
	static let arrayUser = Defaults.Key<[User]>("arrayUser", default: [User(name: "Hello", age: "24")])
	static let setUser = Defaults.Key<Set<User>>("user", default: Set([User(name: "Hello", age: "24")]))
	static let dictionaryUser = Defaults.Key<[String: User]>("dictionaryUser", default: ["user": User(name: "Hello", age: "24")])
}

Defaults[.user].name //=> "Hello"
Defaults[.arrayUser][0].name //=> "Hello"
Defaults[.setUser].first?.name //=> "Hello"
Defaults[.dictionaryUser]["user"]?.name //=> "Hello"
```

### Serialization of Collection

1. Create your Collection and its element should conforms to `Defaults.Serializable`.

```swift
struct Bag<Element: Defaults.Serializable>: Collection {
	var items: [Element]

	var startIndex: Int {
		items.startIndex
	}

	var endIndex: Int {
		items.endIndex
	}

	mutating func insert(element: Element, at: Int) {
		items.insert(element, at: at)
	}

	func index(after index: Int) -> Int {
		items.index(after: index)
	}

	subscript(position: Int) -> Element {
		items[position]
	}
}
```

2. Create an extension of `Bag`. let it conforms to `Defaults.CollectionSerializable`

```swift
extension Bag: Defaults.CollectionSerializable {
	init(_ elements: [Element]) {
		self.items = elements
	}
}

```

3. Create some keys and enjoy it.

```swift
extension Defaults.Keys {
	static let stringBag = Key<Bag<String>>("stringBag", default: Bag(["Hello", "World!"]))
}

Defaults[.stringBag][0] //=> "Hello"
Defaults[.stringBag][1] //=> "World!"
```

### Serialization of SetAlgebra

1. Create your SetAlgebra and its element should conforms to `Defaults.Serializable & Hashable`

```swift
struct SetBag<Element: Defaults.Serializable & Hashable>: SetAlgebra {
	var store = Set<Element>()

	init() {}

	init(_ store: Set<Element>) {
		self.store = store
	}

	func contains(_ member: Element) -> Bool {
		store.contains(member)
	}

	func union(_ other: SetBag) -> SetBag {
		SetBag(store.union(other.store))
	}

	func intersection(_ other: SetBag)
		-> SetBag {
		var setBag = SetBag()
		setBag.store = store.intersection(other.store)
		return setBag
	}

	func symmetricDifference(_ other: SetBag)
		-> SetBag {
		var setBag = SetBag()
		setBag.store = store.symmetricDifference(other.store)
		return setBag
	}

	@discardableResult
	mutating func insert(_ newMember: Element)
		-> (inserted: Bool, memberAfterInsert: Element) {
		store.insert(newMember)
	}

	mutating func remove(_ member: Element) -> Element? {
		store.remove(member)
	}

	mutating func update(with newMember: Element) -> Element? {
		store.update(with: newMember)
	}

	mutating func formUnion(_ other: SetBag) {
		store.formUnion(other.store)
	}

	mutating func formSymmetricDifference(_ other: SetBag) {
		store.formSymmetricDifference(other.store)
	}

	mutating func formIntersection(_ other: SetBag) {
		store.formIntersection(other.store)
	}
}
```

2. Create an extension of `SetBag`. Let it conforms to `Defaults.SetAlgebraSerializable`

```swift
extension SetBag: Defaults.SetAlgebraSerializable {
	func toArray() -> [Element] {
		Array(store)
	}
}
```

3. Create some keys and enjoy it.

```swift
extension Defaults.Keys {
	static let stringSet = Key<SetBag<String>>("stringSet", default: SetBag(["Hello", "World!"]))
}

Defaults[.stringSet].contains("Hello") //=> true
Defaults[.stringSet].contains("World!") //=> true
```

## API

### `Defaults`

#### `Defaults.Keys`

Type: `class`

Stores the keys.

#### `Defaults.Key` _(alias `Defaults.Keys.Key`)_

```swift
Defaults.Key<T>(_ key: String, default: T, suite: UserDefaults = .standard)
```

Type: `class`

Create a key with a default value.

The default value is written to the actual `UserDefaults` and can be used elsewhere. For example, with a Interface Builder binding.

#### `Defaults.Serializable`

```swift
public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	typealias Serializable = Bridge.Serializable
	associatedtype Bridge: Defaults.Bridge

	static var bridge: Bridge { get }
}
```

Type: `protocol`

All types conform to this protocol will be able to work with `Defaults`. 

It should have a static variable `bridge` which protocol should conform to `Defaults.Bridge`.

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

A Bridge can do serialization and de-serialization.

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

#### `Defaults.migrate(keys..., to: Version)`

```swift
Defaults.migrate<T: Defaults.Serializable & Codable>(keys..., to: Version)
Defaults.migrate<T: Defaults.NativeType>(keys..., to: Version)
```

Type: `func`

Migrate the given keys to the specific version.

You can specify up to 10 keys. If you need to specify more, call this method multiple times.

### `@Default(_ key:)`

Get/set a `Defaults` item and also have the view be updated when the value changes.

### Advanced

#### `Defaults.CollectionSerializable`

```swift
public protocol DefaultsCollectionSerializable: Collection, Defaults.Serializable {
	init(_ elements: [Element])
}
```

Type: `protocol`

A `Collection` which can store into the native `UserDefaults`.

It should have an initializer `init(_ elements: [Element])` to let `Defaults` do the de-serialization.

#### `Defaults.SetAlgebraSerializable`

```swift
public protocol DefaultsSetAlgebraSerializable: SetAlgebra, Defaults.Serializable {
	func toArray() -> [Element]
}
```

Type: `protocol`

A `SetAlgebra` which can store into the native `UserDefaults`.

It should have a function `func toArray() -> [Element]` to let `Defaults` do the serialization.

## FAQ

### How can I store a dictionary of arbitrary values?

After `Defaults` v5, you don't need to use `Codable` to store dictionary, `Defaults` supports storing dictionary natively.  
For `Defaults` support types, see [Support types](#support-types).

There might be situations where you want to use `[String: Any]` directly.  
Unfortunately, since `Any` can not conform to `Defaults.Serializable`, `Defaults` can not support it.  

However, you can use the [`AnyCodable`](https://github.com/Flight-School/AnyCodable) package to work around this `Defaults.Serializable` limitation:

```swift
import AnyCodable

/// Important: Let AnyCodable conforms to Defaults.Serializable
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
