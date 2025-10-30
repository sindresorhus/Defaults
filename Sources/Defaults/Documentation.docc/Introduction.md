# Introduction

Learn how to use Defaults to store key-value pairs persistently in your app.

## Overview

Defaults provides a type-safe, Swifty way to work with `UserDefaults`. You declare keys with their types and default values upfront, and Defaults handles the rest.

### Declaring Keys

You declare defaults keys upfront with a type and default value. The key name must be ASCII, not start with `@`, and cannot contain a dot (`.`).

```swift
import Defaults

extension Defaults.Keys {
	static let quality = Key<Double>("quality", default: 0.8)
	//            ^            ^         ^                ^
	//           Key          Type   UserDefaults name   Default value
}
```

### Accessing Values

You can then access values as a subscript on the `Defaults` global:

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

### Optional Keys

You can also declare optional keys for when you don't want to declare a default value upfront:

```swift
extension Defaults.Keys {
	static let name = Key<String?>("name")
}

if let name = Defaults[.name] {
	print(name)
}
```

The default value is then `nil`.

### Dynamic Default Values

You can specify a dynamic default value. This can be useful when the default value may change during the lifetime of the app:

```swift
extension Defaults.Keys {
	static let camera = Key<AVCaptureDevice?>("camera") { .default(for: .video) }
}
```

> Note: A ``Defaults/Key`` with a dynamic default value will not register the default value in `UserDefaults`.

### Using Keys Directly

You are not required to attach keys to ``Defaults/Keys``:

```swift
let isUnicorn = Defaults.Key<Bool>("isUnicorn", default: true)

Defaults[isUnicorn]
//=> true
```

### It's Just UserDefaults with Sugar

This works too:

```swift
extension Defaults.Keys {
	static let isUnicorn = Key<Bool>("isUnicorn", default: true)
}

UserDefaults.standard[.isUnicorn]
//=> true
```

### Shared UserDefaults

You can use a custom `UserDefaults` suite:

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

### Default Value Registration

When you create a ``Defaults/Key``, it automatically registers the `default` value with normal `UserDefaults`. This means you can make use of the default value in, for example, bindings in Interface Builder.

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: true)
}

print(UserDefaults.standard.bool(forKey: Defaults.Keys.isUnicornMode.name))
//=> true
```

### Resetting Keys

You can reset keys back to their default values:

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

This works for a ``Defaults/Key`` with an optional too, which will be reset back to `nil`.

### Observing Changes

You can observe changes to keys using async/await:

```swift
extension Defaults.Keys {
	static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
}

Task {
	for await value in Defaults.updates(.isUnicornMode) {
		print("Value:", value)
	}
}
```

In contrast to the native `UserDefaults` key observation, here you receive a strongly-typed change object.

### Controlling Change Propagation

Changes made within the ``Defaults/withoutPropagation(_:)`` closure will not be propagated to observation callbacks, which can prevent infinite recursion:

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

## Topics

### Keys

- ``Defaults/Keys``
- ``Defaults/Key``

### Accessing Values

- ``Defaults/subscript(_:)``

### Resetting and Removing

- ``Defaults/reset(_:)-7jv5v``
- ``Defaults/reset(_:)-7es1e``
- ``Defaults/removeAll(suite:)``

### Observing Changes

- ``Defaults/updates(_:initial:)-88orv``
- ``Defaults/updates(_:initial:)-l03o``
- ``Defaults/updates(_:initial:)-1mqkb``
- ``Defaults/withoutPropagation(_:)``
