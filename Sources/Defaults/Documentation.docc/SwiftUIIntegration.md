# SwiftUI Integration

Use Defaults seamlessly in SwiftUI with property wrappers and views that automatically update.

## Overview

Defaults provides first-class SwiftUI support through property wrappers and components that automatically update your views when values change.

## Using @Default in Views

The ``Default`` property wrapper lets you get and set Defaults values while automatically updating your view when the value changes. This is similar to `@State`.

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

> Note: It's `@Default`, not `@Defaults`.

> Important: You cannot use `@Default` in an `ObservableObject`. It's meant to be used in a `View`.

## Using @ObservableDefault in Observable Classes

With the `@ObservableDefault` macro, you can use Defaults inside `@Observable` classes that use the [Observation](https://developer.apple.com/documentation/observation) framework.

To use this feature, import both `Defaults` and `DefaultsMacros`, and add the macro along with `@ObservationIgnored` to prevent clashes with `@Observable`:

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

> Warning: Build times will increase when using macros.
>
> Swift macros depend on the [`swift-syntax`](https://github.com/swiftlang/swift-syntax) package. This means that when you compile code that includes macros as dependencies, you also have to compile `swift-syntax`. It is widely known that doing so has serious impact on build time and, while it is an issue that is being tracked (see [`swift-syntax`#2421](https://github.com/swiftlang/swift-syntax/issues/2421)), there's currently no solution implemented.

## Defaults.Toggle Component

Defaults provides a convenient ``Defaults/Toggle`` wrapper for SwiftUI's `Toggle` that makes it easier to create toggles based on Defaults keys with `Bool` values.

### Basic Usage

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

### Listening to Changes

You can observe changes directly on the toggle:

```swift
struct ShowAllDayEventsSetting: View {
	var body: some View {
		Defaults.Toggle("Show All-Day Events", key: .showAllDayEvents)
			// Note: This must be directly attached to Defaults.Toggle, not a regular View#onChange()
			.onChange {
				print("Value", $0)
			}
	}
}
```

> Tip: The `onChange` modifier must be attached directly to `Defaults.Toggle`. It's not the same as `View#onChange()`.

## Importing Without Prefix

If you don't want to import Defaults in every file, add this to a file in your app to use `Defaults` and `@Default` from anywhere without an import:

```swift
import Defaults

typealias Defaults = _Defaults
typealias Default = _Default
```

## Topics

### Property Wrappers

- ``Default``

### Components

- ``Defaults/Toggle``
