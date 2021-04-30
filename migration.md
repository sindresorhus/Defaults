# Migration Guide From v4 to v5

## Warning

If the migration is not success or incomplete. Edit `Defaults.Key` might cause data loss.  
**Please back up your UserDefaults data before migration.**

## Summary

Before v4, `Defaults` store `Codable` types as a JSON string.  
After v5, `Defaults` store `Defaults.Serializable` types with `UserDefaults` native supported type.

```swift
// Before 
let key = Defaults.Key<[String: Int]>("key", default: ["0": 0])

UserDefaults.standard.string(forKey: "key") //=> "["0": 0]"

// After v5
let key = Defaults.Key<[String: Int]>("key", default: ["0": 0])

UserDefaults.standard.dictionary(forKey: "key") //=> [0: 0]
```

All types should conform to `Defaults.Serializable` in order to work with `Defaults`.
So this will require some migrations to resolve **TWO** major issues.

## Issues

1. **Compiler complain that `Defaults.Key<Value>` is not conform to `Defaults.Serializable`.**  
	Since we replace `Codable` with `Defaults.Serializable`, `Key<Value>` will have to conform to `Value: Defaults.Serializable`.  
	For this situation, please follow the guide below:
	- [From `Codable` struct in Defaults v4 to `Codable` struct in Defaults v5](#from-codable-struct-in-defaults-v4-to-codable-struct-in-defaults-v5)
	- [From `Codable` enum in Defaults v4 to `Codable` enum in Defaults v5](#from-codable-enum-in-defaults-v4-to-codable-enum-in-defaults-v5)

2. **Previous value in UserDefaults is not readable. (ex. `Defaults[.array]` return `null`).**
	In v5, `Defaults` reads value from `UserDefaults` as a native supported type.
	But `UserDefaults` only contains JSON string before migration, `Defaults` will not be able to work with it.
	For this situation, `Defaults` provides `Defaults.migrate` method to automate the migration process.
	- [From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Native Supported Elements) in Defaults v5](#from-codable-arraydictionaryset-in-defaults-v4-to-native-arraydictionarysetwith-native-supported-elements-in-defaults-v5)
	- [From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Codable Elements) in Defaults v5](#from-codable-arraydictionaryset-in-defaults-v4-to-native-arraydictionarysetwith-codable-elements-in-defaults-v5)  

	**Caution:**
	- This is a breaking change, there is no way to convert it back to `Codable Array/Dictionary/Set` so far.

- **Optional migration**
	`Defaults` also provide a migration guide to let users convert them `Codable` things into the UserDefaults native supported type, but it is optional.
	- [From `Codable` enum in Defaults v4 to `RawRepresentable` in Defaults v5](#from-codable-enum-in-defaults-v4-to-rawrepresentable-in-defaults-v5-optional)
	- [From `Codable` struct in Defaults v4 to `Dictionary` in Defaults v5](#from-codable-struct-in-defaults-v4-to-dictionary-in-defaults-v5-optional)

## Testing

We recommend user doing some tests after migration.  
The most critical issue is the second one (Previous value in UserDefaults is not readable).  
After migration, there is a need to make sure user can get the same value as before.
You can try to test it manually or making a test file to test it.

Here is the guide for making a migration test:
For example you are trying to migrate a `Codable String` array to native array.

1. Get previous value in UserDefaults (using `defaults` command or whatever you want).

```swift
let string = "[\"a\",\"b\",\"c\"]"
```

2. Insert the value above into UserDefaults.

```swift
UserDefaults.standard.set(string, forKey: "testKey")
```

3. Call `Defaults.migrate` and then using `Defaults` to get its value

```swift
let key = Defaults.Key<[String]>("testKey", default: [])
Defaults.migrate(key, to: .v5)

Defaults[key] //=> [a, b, c]
```

---

### From `Codable` struct in Defaults v4 to `Codable` struct in Defaults v5

Before v4, `struct` have to conform to `Codable` to store it as a JSON string.  

After v5, `struct` have to conform to `Defaults.Serializable & Codable` to store it as a JSON string.  

#### Before migration, your code should be like this

```swift
private struct TimeZone: Codable {
	var id: String
	var name: String
}

extension Defaults.Keys {
	static let timezone = Defaults.Key<TimeZone?>("TimeZone")
}
```

#### Migration steps

1. Let `TimeZone` conform to `Defaults.Serializable`.

```swift
private struct TimeZone: Defaults.Serializable, Codable {
	var id: String
	var name: String
}
```

2. Now `Defaults[.timezone]` should be readable.

---

### From `Codable` enum in Defaults v4 to `Codable` enum in Defaults v5

Before v4, `enum` have to conform to `Codable` to store it as a JSON string.  

After v5, struct have to conform to `Defaults.Serializable & Codable` to store it as a JSON string.  

#### Before migration, your code should be like this

```swift
private enum Period: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let period = Defaults.Key<Period?>("period")
}
```

#### Migration steps

1. Let `Period` conform to `Defaults.Serializable`.

```swift
private enum Period: String, Defaults.Serializable, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}
```

2. Now `Defaults[.period]` should be readable.

---

### From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Native Supported Elements) in Defaults v5

Before v4, `Defaults` will store array/dictionary as a JSON string(`["a", "b", "c"]`).  

After v5, `Defaults` will store it as a native array/dictionary with native supported elements(`[a, b, c]` ). 

#### Before migration, your code should be like this

```swift
extension Defaults.Keys {
	static let arrayString = Defaults.Key<[String]?>("arrayString")
	static let setString = Defaults.Key<Set<String>?>("setString")
	static let dictionaryStringInt = Defaults.Key<[String: Int]?>("dictionaryStringInt")
	static let dictionaryStringIntInArray = Defaults.Key<[[String: Int]]?>("dictionaryStringIntInArray")
}
```

#### Migration steps

1. **Call `Defaults.migration(.arrayString, to: .v5)`, `Defaults.migration(.setString, to: .v5)`, `Defaults.migration(.dictionaryStringInt, to: .v5)`, `Defaults.migration(.dictionaryStringIntInArray, to: .v5)`.**
2. Now `Defaults[.arrayString]`, `Defaults.[.setString]`, `Defaults[.dictionaryStringInt]`, `Defaults[.dictionaryStringIntInArray]` should be readable.

---

### From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Codable Elements) in Defaults v5

Before v4, `Defaults` will store array/dictionary as a JSON string(`"{ "id": "0", "name": "Asia/Taipei" }"`, `"["10 Minutes", "30 Minutes"]"`).    

After v5, `Defaults` will store it as a native array/dictionary with codable elements(`{ id: 0, name: Asia/Taipei }`, `[10 Minutes, 30 Minutes]`).

#### Before migration, your code should be like this

```swift
private struct TimeZone: Codable, Hashable {
	var id: String
	var name: String
}
private enum Period: String, Codable, Hashable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let arrayTimezone = Defaults.Key<[TimeZone]?>("arrayTimezone")
	static let setTimezone = Defaults.Key<[TimeZone]?>("setTimezone")
	static let arrayPeriod = Defaults.Key<[Period]?>("arrayPeriod")
	static let setPeriod = Defaults.Key<[Period]?>("setPeriod")
	static let dictionaryTimezone = Defaults.Key<[String: TimeZone]?>("dictionaryTimezone")
	static let dictionaryPeriod = Defaults.Key<[String: Period]?>("dictionaryPeriod")
}
```

#### Migration steps

1. Let `TimeZone` and `Period` conform to `Defaults.Serializable`

```swift
private struct TimeZone: Defaults.Serializable, Codable, Hashable {
	var id: String
	var name: String
}

private enum Period: String, Defaults.Serializable, Codable, Hashable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}
```

2. **Call `Defaults.migration(.arrayTimezone, to: .v5)`, `Defaults.migration(.setTimezone, to: .v5)`, `Defaults.migration(.dictionaryTimezone, to: .v5)`, `Defaults.migration(.arrayPeriod, to: .v5)`, `Defaults.migration(.setPeriod, to: .v5)` , `Defaults.migration(.dictionaryPeriod, to: .v5)`.**
3. Now `Defaults[.arrayTimezone]`, `Defaults[.setTimezone]`, `Defaults[.dictionaryTimezone]`, `Defaults[.arrayPeriod]`, `Defaults[.setPeriod]` , `Defaults[.dictionaryPeriod]` should be readable.

---

### From `Codable` enum in Defaults v4 to `RawRepresentable` in Defaults v5 (Optional)

Before v4, `Defaults` will store `enum` as a JSON string(`"10 Minutes"`).    

After v5, `Defaults` will store `enum` as a `RawRepresentable`(`10 Minutes`). 

#### Before migration, your code should be like this

```swift
private enum Period: String, Codable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension Defaults.Keys {
	static let period = Defaults.Key<Period?>("period")
}
```

#### Migration steps

1. Create an enum call `CodablePeriod` and create an extension of it. Let it conform to `Defaults.CodableType` and associated `NativeForm` to `Period`.

```swift
private enum CodablePeriod: String {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}

extension CodablePeriod: Defaults.CodableType {
	typealias NativeForm = Period
}
```

2. Remove `Codable`. So `Period` can be stored natively.

```swift
private enum Period: String {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}
```

3. Create an extension of `Period`, let it conform to `Defaults.NativeType` and its `CodableForm` should be `CodablePeriod`.

```swift
extension Period: Defaults.NativeType {
	typealias CodableForm = CodablePeriod
}
```

4. **Call `Defaults.migration(.period)`**
5. Now `Defaults[.period]` should be readable.

* hints: You can also implement `toNative` function at `Defaults.CodableType` in your own way.

For example

```swift
extension CodablePeriod: Defaults.CodableType {
	typealias NativeForm = Period

	public func toNative() -> Period {
		switch self {
		case .tenMinutes:
			return .tenMinutes
		case .halfHour:
			return .halfHour
		case .oneHour:
			return .oneHour
		}
	}
}
```


---

### From `Codable` struct in Defaults v4 to `Dictionary` in Defaults v5 (Optional) 

This happens when you have a struct which is stored as a codable JSON string before, but now you want it to be stored as a native UserDefaults dictionary.

#### Before migration, your code should be like this

```swift
private struct TimeZone: Codable {
	var id: String
	var name: String
}

extension Defaults.Keys {
	static let timezone = Defaults.Key<TimeZone?>("TimeZone")
	static let arrayTimezone = Defaults.Key<[TimeZone]?>("arrayTimezone")
	static let setTimezone = Defaults.Key<Set<TimeZone>?>("setTimezone")
	static let dictionaryTimezone = Defaults.Key<[String: TimeZone]?>("setTimezone")
}
```

#### Migration steps

1. Create a `TimeZoneBridge` which conform to `Defaults.Bridge` and its `Value` is TimeZone, `Serializable` is `[String: String]`.

```swift
private struct TimeZoneBridge: Defaults.Bridge {
	typealias Value = TimeZone
	typealias Serializable = [String: String]

	func serialize(_ value: TimeZone?) -> Serializable? {
		guard let value = value else {
			return nil
		}

		return ["id": value.id, "name": value.name]
	}

	func deserialize(_ object: Serializable?) -> TimeZone? {
		guard
			let dictionary = object,
			let id = dictionary["id"],
			let name = dictionary["name"]
		else {
			return nil
		}

		return TimeZone(id: id, name: name)
	}
}
```

2. Create an extension of `TimeZone`, let it conform to `Defaults.NativeType` and its static bridge is `TimeZoneBridge`(Compiler will complain that `TimeZone` is not conform to `Defaults.NativeType`, will resolve it later).

```swift
private struct TimeZone: Hashable {
	var id: String
	var name: String
}

extension TimeZone: Defaults.NativeType {
	static let bridge = TimeZoneBridge()
}
```

3. Create an extension of `CodableTimeZone` and let it conform to `Defaults.CodableType`

```swift
private struct CodableTimeZone {
	var id: String
	var name: String
}

extension CodableTimeZone: Defaults.CodableType {
	/// Convert from `Codable` to `Native`
	func toNative() -> TimeZone {
		TimeZone(id: id, name: name)
	}
}
```

4. Associate `TimeZone.CodableForm` to `CodableTimeZone`

```swift
extension TimeZone: Defaults.NativeType {
	/// Associated `CodableForm` to `CodableTimeZone`
	typealias CodableForm = CodableTimeZone

	static let bridge = TimeZoneBridge()
}
```

5. **Call `Defaults.migration(.timezone, to: .v5)`, `Defaults.migration(.arrayTimezone, to: .v5)`, `Defaults.migration(.setTimezone, to: .v5)`, `Defaults.migration(.dictionaryTimezone, to: .v5)`**.
6. Now `Defaults[.timezone]`, `Defaults[.arrayTimezone]` , `Defaults[.setTimezone]`, `Defaults[.dictionaryTimezone]` should be readable.

**See [DefaultsMigrationTests.swift](./Tests/DefaultsTests/DefaultsMigrationTests.swift) for more example.**