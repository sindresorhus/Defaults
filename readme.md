# Defaults [![Build Status](https://travis-ci.org/sindresorhus/Defaults.svg?branch=master)](https://travis-ci.org/sindresorhus/Defaults)

> Swifty and modern [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)


## Highlights

- **Strongly typed:** You declare the type and default value upfront.
- **Codable support:** You can store any [Codable](https://developer.apple.com/documentation/swift/codable) value, like an enum.
- **Debuggable:** The data is stored as JSON-serialized values.
- **Lightweight:** It's only ~100 lines of code.


## Compatibility

- macOS 10.12+
- iOS 10+
- tvOS 10+
- watchOS 3+


## Install

#### SPM

```swift
.package(url: "https://github.com/sindresorhus/Defaults", from: "0.2.0")
```

#### Carthage

```
github "sindresorhus/Defaults"
```

#### CocoaPods

```ruby
pod 'Defaults'
```

<a href="https://www.patreon.com/sindresorhus">
	<img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>


## Usage

You declare the defaults keys upfront with type and default value.

```swift
import Cocoa
import Defaults

extension Defaults.Keys {
	static let quality = Defaults.Key<Double>("quality", default: 0.8)
	//            ^                     ^         ^                ^
	//           Key                   Type   UserDefaults name   Default value
}
```

You can then access it as a subscript on the `defaults` global (note lowercase):

```swift
defaults[.quality]
//=> 0.8

defaults[.quality] = 0.5
//=> 0.5

defaults[.quality] += 0.1
//=> 0.6

defaults[.quality] = "🦄"
//=> [Cannot assign value of type 'String' to type 'Double']
```

You can also declare optional keys for when you don't want to declare a default value upfront:

```swift
extension Defaults.Keys {
	static let name = Defaults.OptionalKey<Double>("name")
}

if let name = defaults[.name] {
	print(name)
}
```


### Enum example

```swift
enum DurationKeys: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let defaultDuration = Defaults.Key<DurationKeys>("defaultDuration", default: .oneHour)
}

defaults[.defaultDuration].rawValue
//=> "1 Hour"
```


### It's just UserDefaults with sugar

This works too:

```swift
extension Defaults.Keys {
	static let isUnicorn = Defaults.Key<Bool>("isUnicorn", default: true)
}

UserDefaults.standard[.isUnicorn]
//=> true
```


### Shared UserDefaults

```swift
extension Defaults.Keys {
	static let isUnicorn = Defaults.Key<Bool>("isUnicorn", default: true)
}

let extensionDefaults = UserDefaults(suiteName: "com.unicorn.app")!

extensionDefaults[.isUnicorn]
//=> true
```


## API

### `let defaults = Defaults()`

#### Defaults.Keys

Type: `class`

Stores the keys.

#### Defaults.Key

Type: `class`

Create a key with a default value.

#### Defaults.OptionalKey

Type: `class`

Create a key with an optional value.

##### defaults.clear()

Type: `func`

Clear the user defaults.


## FAQ

### How is this different from [`SwiftyUserDefaults`](https://github.com/radex/SwiftyUserDefaults)?

It's inspired by it and other solutions. The main difference is that this module doesn't hardcode the default values and comes with Codable support.


## Related

- [Preferences](https://github.com/sindresorhus/Preferences) - Add a preferences window to your macOS app in minutes
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [DockProgress](https://github.com/sindresorhus/DockProgress) - Show progress in your app's Dock icon
- [Gifski](https://github.com/sindresorhus/gifski-app) - Convert videos to high-quality GIFs on your Mac


## License

MIT © [Sindre Sorhus](https://sindresorhus.com)
