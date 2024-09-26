# Defaults

> Swifty and modern [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)

Store key-value pairs persistently across launches of your app.

It uses `UserDefaults` underneath but exposes a type-safe facade with lots of nice conveniences.

It's used in production by [all my apps](https://sindresorhus.com/apps) (4 million+ users).

## Highlights

- **Strongly typed:** You declare the type and default value upfront.
- **SwiftUI:** Property wrapper that updates the view when the `UserDefaults` value changes.
- **Codable support:** You can store any [Codable](https://developer.apple.com/documentation/swift/codable) value, like an enum.
- **NSSecureCoding support:** You can store any [NSSecureCoding](https://developer.apple.com/documentation/foundation/nssecurecoding) value.
- **Observation:** Observe changes to keys.
- **Debuggable:** The data is stored as JSON-serialized values.
- **Customizable:** You can serialize and deserialize your own type in your own way.
- **iCloud support:** Automatically synchronize data between devices.

## Benefits over `@AppStorage`

- You define strongly-typed identifiers in a single place and can use them everywhere.
- You also define the default values in a single place instead of having to remember what default value you used in other places.
- You can use it outside of SwiftUI.
- You can observe value updates.
- Supports many more types, even `Codable`.
- Easy to add support for your own custom types.
- Comes with a convenience SwiftUI `Toggle` component.

## Compatibility

- macOS 11+
- iOS 14+
- tvOS 14+
- watchOS 9+
- visionOS 1+

## Install

Add `https://github.com/sindresorhus/Defaults` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## Support types

- `Int(8/16/32/64)`
- `UInt(8/16/32/64)`
- `Double`
- `CGFloat`
- `Float`
- `String`
- `Bool`
- `Date`
- `Data`
- `URL`
- `UUID`
- `Range`
- `ClosedRange`
- `Codable`
- `NSSecureCoding`
- `Color` [^1] (SwiftUI)
- `Color.Resolved` [^1] (SwiftUI)
- `NSColor`
- `UIColor`
- `NSFontDescriptor`
- `UIFontDescriptor`

Defaults also support the above types wrapped in `Array`, `Set`, `Dictionary`, `Range`, `ClosedRange`, and even wrapped in nested types. For example, `[[String: Set<[String: Int]>]]`.

For more types, see the [enum example](#enum-example), [`Codable` example](#codable-example), or [advanced Usage](#advanced-usage). For more examples, see [Tests/DefaultsTests](./Tests/DefaultsTests).

You can easily add support for any custom type.

If a type conforms to both `NSSecureCoding` and `Codable`, then `Codable` will be used for the serialization.

[^1]: [You cannot use `Color.accentColor`.](https://github.com/sindresorhus/Defaults/issues/139)

## Usage

[API documentation.](https://swiftpackageindex.com/sindresorhus/Defaults/documentation/defaults)

You declare the defaults keys upfront with a type and default value.

**The key name must be ASCII, not start with `@`, and cannot contain a dot (`.`).**

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

You can also specify a dynamic default value. This can be useful when the default value may change during the lifetime of the app:

```swift
extension Defaults.Keys {
	static let camera = Key<AVCaptureDevice?>("camera") { .default(for: .video) }
}
```

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

*(This works as long as the raw value of the enum is any of the supported types)*

### Codable example

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

#### `@Default` in `View`

You can use the `@Default` property wrapper to get/set a `Defaults` item and also have the view be updated when the value changes. This is similar to `@State`.

```swift
extension Defaults.Keys {
	static let hasUnicorn = Key<Bool>("hasUnicorn", default: false)
}

struct ContentView: View {
	@Default(.hasUnicorn) var hasUnicorn

	var body: some View {
		Text("Has Unicorn: \(hasUnicorn)")
		Toggle("Toggle", isOn: $hasUnicorn)
		Button("Reset") {
			_hasUnicorn.reset()
		}
	}
}
```

Note that it's `@Default`, not `@Defaults`.

You cannot use `@Default` in an `ObservableObject`. It's meant to be used in a `View`.

#### `@ObservableDefault` in `@Observable`

With the `@ObservableDefault` macro, you can use `Defaults` inside `@Observable` classes that use the [Observation](https://developer.apple.com/documentation/observation) framework. Doing so is as simple as importing `DefaultsMacros` and adding two lines to a property (note that adding `@ObservationIgnored` is needed to prevent clashes with `@Observable`):

> [!IMPORTANT] 
> Build times will increase when using macros.
> 
> Swift macros depend on the [`swift-syntax`](https://github.com/swiftlang/swift-syntax) package. This means that when you compile code that includes macros as dependencies, you also have to compile `swift-syntax`. It is widely known that doing so has serious impact in build time and, while it is an issue that is being tracked (see [`swift-syntax`#2421](https://github.com/swiftlang/swift-syntax/issues/2421)), there's currently no solution implemented.

```swift
import Defaults
import DefaultsMacros

@Observable
final class UnicornManager {
	@ObservableDefault(.hasUnicorn)
	@ObservationIgnored
	var hasUnicorn: Bool
}
```

#### `Toggle`

There's also a `SwiftUI.Toggle` wrapper that makes it easier to create a toggle based on a `Defaults` key with a `Bool` value.

```swift
extension Defaults.Keys {
	static let showAllDayEvents = Key<Bool>("showAllDayEvents", default: false)
}

struct ShowAllDayEventsSetting: View {
	var body: some View {
		Defaults.Toggle("Show All-Day Events", key: .showAllDayEvents)
	}
}
```

You can also listen to changes:

```swift
struct ShowAllDayEventsSetting: View {
	var body: some View {
		Defaults.Toggle("Show All-Day Events", key: .showAllDayEvents)
			// Note that this has to be directly attached to `Defaults.Toggle`. It's not `View#onChange()`.
			.onChange {
				print("Value", $0)
			}
	}
}
```

### Observe changes to a key

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
}

// …

Task {
	for await value in Defaults.updates(.isUnicornMode) {
		print("Value:", value)
	}
}
```

In contrast to the native `UserDefaults` key observation, here you receive a strongly-typed change object.

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

> **Note** 
> A `Defaults.Key` with a dynamic default value will not register the default value in `UserDefaults`.

## API

### `Defaults`

#### `Defaults.Keys`

Type: `class`

Stores the keys.

#### `Defaults.Key` _(alias `Defaults.Keys.Key`)_

```swift
Defaults.Key<T>(_ name: String, default: T, suite: UserDefaults = .standard)
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

Types that conform to this protocol can be used with `Defaults`.

The type should have a static variable `bridge` which should reference an instance of a type that conforms to `Defaults.Bridge`.

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

A `Bridge` is responsible for serialization and deserialization.

It has two associated types `Value` and `Serializable`.

- `Value`: The type you want to use.
- `Serializable`: The type stored in `UserDefaults`.
- `serialize`: Executed before storing to the `UserDefaults` .
- `deserialize`: Executed after retrieving its value from the `UserDefaults`.

#### `Defaults.AnySerializable`

```swift
Defaults.AnySerializable<Value: Defaults.Serializable>(_ value: Value)
```

Type: `class`

Type-erased wrapper for `Defaults.Serializable` values.

- `get<Value: Defaults.Serializable>() -> Value?`: Retrieve the value which type is `Value` from UserDefaults.
- `get<Value: Defaults.Serializable>(_: Value.Type) -> Value?`: Specify the `Value` you want to retrieve. This can be useful in some ambiguous cases.
- `set<Value: Defaults.Serializable>(_ newValue: Value)`: Set a new value for `Defaults.AnySerializable`.

#### `Defaults.reset(keys…)`

Type: `func`

Reset the given keys back to their default values.

You can also specify string keys, which can be useful if you need to store some keys in a collection, as it's not possible to store `Defaults.Key` in a collection because it's generic.

#### `Defaults.removeAll`

```swift
Defaults.removeAll(suite: UserDefaults = .standard)
```

Type: `func`

Remove all entries from the given `UserDefaults` suite.

#### `Defaults.withoutPropagation(_ closure:)`

Execute the closure without triggering change events.

Any `Defaults` key changes made within the closure will not propagate to `Defaults` event listeners (`Defaults.observe()` and `Defaults.publisher()`). This can be useful to prevent infinite recursion when you want to change a key in the callback listening to changes for the same key.

### `@Default(_ key:)`

Get/set a `Defaults` item and also have the SwiftUI view be updated when the value changes.

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

## Advanced usage

### Custom types

Although `Defaults` already has built-in support for many types, you might need to be able to use your own custom type. The below guide will show you how to make your own custom type work with `Defaults`.

1. Create your own custom type.

```swift
struct User {
	let name: String
	let age: String
}
```

2. Create a bridge that conforms to `Defaults.Bridge`, which is responsible for handling serialization and deserialization.

```swift
struct UserBridge: Defaults.Bridge {
	typealias Value = User
	typealias Serializable = [String: String]

	public func serialize(_ value: Value?) -> Serializable? {
		guard let value else {
			return nil
		}

		return [
			"name": value.name,
			"age": value.age
		]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object,
			let name = object["name"],
			let age = object["age"]
		else {
			return nil
		}

		return User(
			name: name,
			age: age
		)
	}
}
```

3. Create an extension of `User` that conforms to `Defaults.Serializable`. Its static bridge should be the bridge we created above.

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

### Dynamic value

There might be situations where you want to use `[String: Any]` directly, but `Defaults` need its values to conform to `Defaults.Serializable`. The type-eraser `Defaults.AnySerializable` helps overcome this limitation.

`Defaults.AnySerializable` is only available for values that conform to `Defaults.Serializable`.

Warning: The type-eraser should only be used when there's no other way to handle it because it has much worse performance. It should only be used in wrapped types. For example, wrapped in `Array`, `Set` or `Dictionary`.

#### Primitive type

`Defaults.AnySerializable` conforms to `ExpressibleByStringLiteral`, `ExpressibleByIntegerLiteral`, `ExpressibleByFloatLiteral`, `ExpressibleByBooleanLiteral`, `ExpressibleByNilLiteral`, `ExpressibleByArrayLiteral`, and `ExpressibleByDictionaryLiteral`.

Which means you can assign these primitive types directly:

```swift
let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: 1)
Defaults[any] = "🦄"
```

#### Other types

##### Using `get` and `set`

For other types, you will have to assign it like this:

```swift
enum mime: String, Defaults.Serializable {
	case JSON = "application/json"
	case STREAM = "application/octet-stream"
}

let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: [Defaults.AnySerializable(mime.JSON)])

if let mimeType: mime = Defaults[any].get() {
	print(mimeType.rawValue)
	//=> "application/json"
}

Defaults[any].set(mime.STREAM)

if let mimeType: mime = Defaults[any].get() {
	print(mimeType.rawValue)
	//=> "application/octet-stream"
}
```

#### Wrapped in `Array`, `Set`, or `Dictionary`

`Defaults.AnySerializable` also support the above types wrapped in `Array`, `Set`, `Dictionary`.

Here is the example for `[String: Defaults.AnySerializable]`:

```swift
extension Defaults.Keys {
	static let magic = Key<[String: Defaults.AnySerializable]>("magic", default: [:])
}

enum mime: String, Defaults.Serializable {
	case JSON = "application/json"
}

// …
Defaults[.magic]["unicorn"] = "🦄"

if let value: String = Defaults[.magic]["unicorn"]?.get() {
	print(value)
	//=> "🦄"
}

Defaults[.magic]["number"] = 3
Defaults[.magic]["boolean"] = true
Defaults[.magic]["enum"] = Defaults.AnySerializable(mime.JSON)

if let mimeType: mime = Defaults[.magic]["enum"]?.get() {
	print(mimeType.rawValue)
	//=> "application/json"
}
```

For more examples, see [Tests/DefaultsAnySerializableTests](./Tests/DefaultsTests/DefaultsAnySeriliazableTests.swift).

### Serialization for ambiguous `Codable` type

You may have a type that conforms to `Codable & NSSecureCoding` or a `Codable & RawRepresentable` enum. By default, `Defaults` will prefer the `Codable` conformance and use the `CodableBridge` to serialize it into a JSON string. If you want to serialize it as a `NSSecureCoding` data or use the raw value of the `RawRepresentable` enum, you can conform to `Defaults.PreferNSSecureCoding` or `Defaults.PreferRawRepresentable` to override the default bridge:

```swift
enum mime: String, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
	case JSON = "application/json"
}

extension Defaults.Keys {
	static let magic = Key<[String: Defaults.AnySerializable]>("magic", default: [:])
}

print(UserDefaults.standard.string(forKey: "magic"))
//=> application/json
```

Had we not added `Defaults.PreferRawRepresentable`, the stored representation would have been `"application/json"` instead of `application/json`.

This can also be useful if you conform a type you don't control to `Defaults.Serializable` as the type could receive `Codable` conformance at any time and then the stored representation would change, which could make the value unreadable. By explicitly defining which bridge to use, you ensure the stored representation will always stay the same.

### Custom `Collection` type

1. Create your `Collection` and make its elements conform to `Defaults.Serializable`.

```swift
struct Bag<Element: Defaults.Serializable>: Collection {
	var items: [Element]

	var startIndex: Int { items.startIndex }
	var endIndex: Int { items.endIndex }

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

2. Create an extension of `Bag` that conforms to `Defaults.CollectionSerializable`.

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

### Custom `SetAlgebra` type

1. Create your `SetAlgebra` and make its elements conform to `Defaults.Serializable & Hashable`

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

	func intersection(_ other: SetBag) -> SetBag {
		var setBag = SetBag()
		setBag.store = store.intersection(other.store)
		return setBag
	}

	func symmetricDifference(_ other: SetBag) -> SetBag {
		var setBag = SetBag()
		setBag.store = store.symmetricDifference(other.store)
		return setBag
	}

	@discardableResult
	mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
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

2. Create an extension of `SetBag` that conforms to `Defaults.SetAlgebraSerializable`

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

## FAQ

### How can I store a dictionary of arbitrary values?

After `Defaults` v5, you don't need to use `Codable` to store dictionary, `Defaults` supports storing dictionary natively.
For `Defaults` support types, see [Support types](#support-types).

### How is this different from [`SwiftyUserDefaults`](https://github.com/radex/SwiftyUserDefaults)?

It's inspired by that package and other solutions. The main difference is that this module doesn't hardcode the default values and comes with Codable support.

## Maintainers

- [Sindre Sorhus](https://github.com/sindresorhus)
- [@hank121314](https://github.com/hank121314)

**Former**

- [Kacper Rączy](https://github.com/fredyshox)

## Related

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Add user-customizable global keyboard shortcuts to your macOS app
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [DockProgress](https://github.com/sindresorhus/DockProgress) - Show progress in your app's Dock icon
- [Gifski](https://github.com/sindresorhus/Gifski) - Convert videos to high-quality GIFs on your Mac
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift+archived%3Afalse&type=repositories)
