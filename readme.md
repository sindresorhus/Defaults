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

## Documentation

[**Full documentation**](https://swiftpackageindex.com/sindresorhus/Defaults/documentation/defaults)

## Usage

```swift
import Defaults

extension Defaults.Keys {
	static let quality = Key<Double>("quality", default: 0.8)
}

Defaults[.quality]
//=> 0.8

Defaults[.quality] = 0.5
//=> 0.5
```

You can also use it in SwiftUI:

```swift
struct ContentView: View {
	@Default(.quality) var quality

	var body: some View {
		Slider(value: $quality, in: 0...1)
	}
}
```

## Maintainers

- [Sindre Sorhus](https://github.com/sindresorhus)
- [@hank121314](https://github.com/hank121314)

## Related

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Add user-customizable global keyboard shortcuts to your macOS app
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [DockProgress](https://github.com/sindresorhus/DockProgress) - Show progress in your app's Dock icon
- [Gifski](https://github.com/sindresorhus/Gifski) - Convert videos to high-quality GIFs on your Mac
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift+archived%3Afalse&type=repositories)
