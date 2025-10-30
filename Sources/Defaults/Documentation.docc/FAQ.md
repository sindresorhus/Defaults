# FAQ

Frequently asked questions about Defaults.

## Overview

This article answers common questions about using Defaults in your projects.

## How can I store a dictionary of arbitrary values?

As of Defaults v5, you don't need to use `Codable` to store dictionaries. Defaults supports storing dictionaries natively.

For all supported types, see <doc:SupportedTypes>.

For flexible dictionaries with mixed value types, you can use ``Defaults/AnySerializable``:

```swift
extension Defaults.Keys {
	static let settings = Key<[String: Defaults.AnySerializable]>("settings", default: [:])
}

Defaults[.settings]["theme"] = "dark"
Defaults[.settings]["fontSize"] = 14
Defaults[.settings]["enabled"] = true
```

See <doc:AdvancedUsage#Type-Erasure-with-AnySerializable> for more information.

## How is this different from SwiftyUserDefaults?

Defaults is inspired by [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults) and similar packages. The main differences are:

- **No Hardcoded Defaults**: Default values are declared with keys, not hardcoded throughout your app
- **Codable Support**: Native support for `Codable` types out of the box
- **SwiftUI Integration**: First-class SwiftUI support with property wrappers
- **Type Safety**: Strongly typed with full compiler support
- **Modern Swift**: Built with modern Swift features like async/await

## Can I use Defaults with iCloud sync?

Yes! Defaults supports iCloud sync through `NSUbiquitousKeyValueStore`. See ``Defaults/iCloud`` for more information about enabling and using iCloud synchronization.

## Does Defaults work with App Groups?

Yes. You can use Defaults with shared `UserDefaults` suites for App Groups:

```swift
let sharedDefaults = UserDefaults(suiteName: "group.com.example.app")!

extension Defaults.Keys {
	static let sharedCounter = Key<Int>("counter", default: 0, suite: sharedDefaults)
}
```

See the [Shared UserDefaults](<doc:Introduction#Shared-UserDefaults>) section for more details.

## Why can't I observe changes in an ObservableObject?

The ``Default`` property wrapper is designed for use in SwiftUI views, not `ObservableObject` classes. For observable objects, use the `@ObservableDefault` macro instead:

```swift
import Defaults
import DefaultsMacros

@Observable
final class Settings {
	@ObservableDefault(.theme)
	@ObservationIgnored
	var theme: String
}
```

See <doc:SwiftUIIntegration#Using-ObservableDefault-in-Observable-Classes> for more information.

## Can I store optional values?

Yes. You can create keys with optional types by omitting the default value:

```swift
extension Defaults.Keys {
	static let userName = Key<String?>("userName")
}

// Default value is nil
Defaults[.userName] //=> nil

// Set a value
Defaults[.userName] = "Alice"

// Reset to nil
Defaults.reset(.userName)
```

See the [Optional Keys](<doc:Introduction#Optional-Keys>) section for more details.

## How do I migrate from @AppStorage to Defaults?

Migrating from `@AppStorage` is straightforward:

**Before (with @AppStorage):**
```swift
struct SettingsView: View {
	@AppStorage("showPreview") var showPreview = true

	var body: some View {
		Toggle("Show Preview", isOn: $showPreview)
	}
}
```

**After (with Defaults):**
```swift
extension Defaults.Keys {
	static let showPreview = Key<Bool>("showPreview", default: true)
}

struct SettingsView: View {
	@Default(.showPreview) var showPreview

	var body: some View {
		Toggle("Show Preview", isOn: $showPreview)
	}
}
```

The key name and default value are now centralized, and you can use them throughout your app.

## Can I use Defaults outside of SwiftUI?

Absolutely! Defaults works everywhere, not just in SwiftUI:

```swift
// In any Swift code
Defaults[.userName] = "Alice"

// Observe changes with async/await
Task {
	for await value in Defaults.updates(.userName) {
		print("User name changed to:", value)
	}
}
```

This is one of the key advantages over `@AppStorage`, which only works in SwiftUI views.

## How is data stored?

Defaults stores data using the underlying `UserDefaults` system. For most types, values are stored as JSON-serialized data, which makes them:

- **Debuggable**: You can inspect values in the terminal or Xcode
- **Portable**: Easy to migrate or backup
- **Human-readable**: JSON format is easy to understand

For types that conform to `RawRepresentable` with simple raw values, or types using `NSSecureCoding`, the native format is used instead.

## Does Defaults affect app performance?

Defaults is designed to be lightweight and efficient:

- Minimal overhead over raw `UserDefaults`
- Type-safe with no runtime type checking needed
- No reflection or dynamic lookups
- Efficient serialization using native Swift features

The only exception is ``Defaults/AnySerializable``, which has additional overhead due to type erasure and should only be used when necessary.

## What about data migration?

Since Defaults uses `UserDefaults` underneath, it's compatible with existing `UserDefaults` data. You can:

- Gradually adopt Defaults in an existing app
- Mix Defaults and raw `UserDefaults` calls
- Access the same keys from both APIs

```swift
extension Defaults.Keys {
	static let theme = Key<String>("theme", default: "light")
}

// These access the same value
Defaults[.theme] = "dark"
UserDefaults.standard.string(forKey: "theme") //=> "dark"
```

## Topics

### Related Documentation

- <doc:Introduction>
- <doc:SupportedTypes>
- <doc:SwiftUIIntegration>
- <doc:AdvancedUsage>
