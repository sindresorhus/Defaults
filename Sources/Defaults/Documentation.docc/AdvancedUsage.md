# Advanced Usage

Extend Defaults to support your own custom types using bridges and serialization protocols.

## Overview

While Defaults supports many types out of the box, you may need to store your own custom types. This guide shows you how to make any type work with Defaults using the ``Defaults/Serializable`` protocol and ``Defaults/Bridge`` system.

## Create Custom Serializable Types

Follow these steps to adapt your own models for Defaults storage.

### Step 1: Define your type

```swift
struct User: Hashable {
	let name: String
	let age: String
}
```

*Note:* Conforming to `Hashable` now saves you from rework later when you need to store `User` in sets or dictionaries.

### Step 2: Create a bridge

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

The bridge exposes two associated types:
- **Value**: The domain type you want to use.
- **Serializable**: A Defaults-compatible representation that is stored in `UserDefaults`.

### Step 3: Conform to ``Defaults/Serializable``

```swift
extension User: Defaults.Serializable {
	static let bridge = UserBridge()
}
```

### Step 4: Register keys

```swift
extension Defaults.Keys {
	static let user = Key<User>("user", default: .init(name: "Hello", age: "24"))
	static let users = Key<Set<User>>("users", default: Set([.init(name: "Hello", age: "24")]))
	static let usersArray = Key<[User]>("usersArray", default: [.init(name: "Hello", age: "24")])
	static let usersByIdentifier = Key<[String: User]>("usersByIdentifier", default: ["user": .init(name: "Hello", age: "24")])
}

Defaults[.user].name //=> "Hello"
Defaults[.users].first?.name //=> "Hello"
Defaults[.usersArray][0].name //=> "Hello"
Defaults[.usersByIdentifier]["user"]?.name //=> "Hello"
```

## Select a Preferred Bridge

If your type conforms to multiple serialization protocols (for example `Codable & NSSecureCoding` or `Codable & RawRepresentable`), Defaults will prefer `Codable` automatically.

Adopt ``Defaults/PreferNSSecureCoding`` or ``Defaults/PreferRawRepresentable`` to override that choice:

```swift
enum Mime: String, Codable, Defaults.Serializable, Defaults.PreferRawRepresentable {
	case json = "application/json"
}

extension Defaults.Keys {
	static let mime = Key<Mime>("mime", default: .json)
}

print(UserDefaults.standard.string(forKey: "mime"))
//=> "application/json" (raw value, not JSON string)
```

*Tip:* Prefer raw values when you need wire compatibility with older app versions or external tooling that already expects the raw representation.

*Important:* Changing the preferred bridge for a key that already ships in production can break stored values. Always roll out migrations or guard rails alongside a bridge change.

## Built-In Bridges at a Glance

Defaults ships with several bridges you can reuse before writing your own:

- ``Defaults.TopLevelCodableBridge`` encodes values with `JSONEncoder` and keeps the payload human-readable.
- ``Defaults.RawRepresentableBridge`` stores enums and other raw-representable types without JSON overhead.
- ``Defaults.NSSecureCodingBridge`` archives Objective-C classes (for example `NSColor`) with secure coding.
- ``Defaults.OptionalBridge`` unwraps optionals so you only implement the serialization logic once.
- ``Defaults.ArrayBridge``, ``Defaults.SetBridge``, and ``Defaults.DictionaryBridge`` adapt Swift collections by applying the element bridge recursively.

Reach for a custom bridge only when none of these cover your scenario.

## Work With Custom Collections

Leverage ``Defaults/CollectionSerializable`` and ``Defaults/SetAlgebraSerializable`` to persist bespoke containers.

*Tip:* Keep your custom collection API thin; Defaults only needs a way to turn the collection into an array and back again.

### Collection types

```swift
struct Bag<Element: Defaults.Serializable>: Collection {
	var items: [Element]

	var startIndex: Int { items.startIndex }
	var endIndex: Int { items.endIndex }

	mutating func insert(element: Element, at index: Int) {
		items.insert(element, at: index)
	}

	func index(after index: Int) -> Int {
		items.index(after: index)
	}

	subscript(position: Int) -> Element {
		items[position]
	}
}

extension Bag: Defaults.CollectionSerializable {
	init(_ elements: [Element]) {
		self.items = elements
	}
}

extension Defaults.Keys {
	static let stringBag = Key<Bag<String>>("stringBag", default: Bag(["Hello", "World!"]))
}

Defaults[.stringBag][0] //=> "Hello"
Defaults[.stringBag][1] //=> "World!"
```

### Set algebra types

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

extension SetBag: Defaults.SetAlgebraSerializable {
	func toArray() -> [Element] {
		Array(store)
	}
}

extension Defaults.Keys {
	static let stringSet = Key<SetBag<String>>("stringSet", default: SetBag(["Hello", "World!"]))
}

Defaults[.stringSet].contains("Hello") //=> true
Defaults[.stringSet].contains("World!") //=> true
```

## Type Erasure with AnySerializable

Use ``Defaults/AnySerializable`` when you must store heterogenous payloads like `[String: Any]`.

*Caution:* `Defaults.AnySerializable` incurs additional allocations and lookups. Prefer concrete `Defaults.Serializable` types whenever possible.

*Tip:* Treat `Defaults.AnySerializable` as a temporary escape hatch. If a schema stabilizes, promote it to a dedicated `Defaults.Serializable` model to regain type safety.

### Primitive assignments

``Defaults/AnySerializable`` conforms to literal protocols so you can write values directly:

```swift
let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: 1)
Defaults[any] = "🦄"
```

### Working with typed values

```swift
enum Mime: String, Defaults.Serializable {
	case json = "application/json"
	case stream = "application/octet-stream"
}

let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: Defaults.AnySerializable(Mime.json))

if let mimeType: Mime = Defaults[any].get() {
	print(mimeType.rawValue)
	//=> "application/json"
}

Defaults[any].set(Mime.stream)

if let mimeType: Mime = Defaults[any].get() {
	print(mimeType.rawValue)
	//=> "application/octet-stream"
}
```

### Dictionary example

```swift
extension Defaults.Keys {
	static let magic = Key<[String: Defaults.AnySerializable]>("magic", default: [:])
}

enum Mime: String, Defaults.Serializable {
	case json = "application/json"
}

Defaults[.magic]["unicorn"] = "🦄"

if let value: String = Defaults[.magic]["unicorn"]?.get() {
	print(value)
	//=> "🦄"
}

Defaults[.magic]["number"] = 3
Defaults[.magic]["boolean"] = true
Defaults[.magic]["enum"] = Defaults.AnySerializable(Mime.json)

if let mimeType: Mime = Defaults[.magic]["enum"]?.get() {
	print(mimeType.rawValue)
	//=> "application/json"
}
```

## Topics

### Custom Types

- ``Defaults/Serializable``
- ``Defaults/Bridge``

### Bridges

- ``Defaults/TopLevelCodableBridge``
- ``Defaults/RawRepresentableBridge``
- ``Defaults/NSSecureCodingBridge``
- ``Defaults/OptionalBridge``
- ``Defaults/ArrayBridge``
- ``Defaults/DictionaryBridge``
- ``Defaults/SetBridge``

### Collections

- ``Defaults/CollectionSerializable``
- ``Defaults/SetAlgebraSerializable``

### Type Erasure

- ``Defaults/AnySerializable``

### Disambiguation

- ``Defaults/PreferRawRepresentable``
- ``Defaults/PreferNSSecureCoding``
