# Migration Guide From v4 to v5

## Summary

After upgrading from v4 to v5, there are **TWO** major issues that we need to resolve.

1. **Compiler complain that `Defaults.Key<Value>` is not conform to `Defaults.Serializable`.**  

	Please follow the steps below:
	- [From `Codable` struct in Defaults v4 to `Codable` struct in Defaults v5](#from-codable-struct-in-defaults-v4-to-codable-struct-in-defaults-v5)
	- [From `Codable` enum in Defaults v4 to `Codable` enum in Defaults v5](#from-codable-enum-in-defaults-v4-to-codable-enum-in-defaults-v5)


2. **Previous value in UserDefaults is not readable. (ex. `Defaults[.array]` return `null`).**

	Please follow the steps below:
	- [From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Native Supported Elements) in Defaults v5](#from-codable-arraydictionaryset-in-defaults-v4-to-native-arraydictionarysetwith-native-supported-elements-in-defaults-v5)
	- [From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Codable Elements) in Defaults v5](#from-codable-arraydictionaryset-in-defaults-v4-to-native-arraydictionarysetwith-codable-elements-in-defaults-v5)  

	**Caution:**
	- This is a breaking change, there is no way to convert it back to `Codable Array/Dictionary/Set` so far.
	- If the migration is not successful or incomplete. Edit `Defaults.Key` might cause data loss.


3. **Optional migration**

	Defaults also provide a migration guide to let users convert them `Codable` things into the `UserDefaults NativeSupported` type, but it's optional.

	- [From `Codable` enum in Defaults v4 to `RawRepresentable` in Defaults v5](#from-codable-enum-in-defaults-v4-to-rawrepresentable-in-defaults-v5-optional)
	- [From `Codable` struct in Defaults v4 to `Dictionary` in Defaults v5](#from-codable-struct-in-defaults-v4-to-dictionary-in-defaults-v5-optional)

---

### From `Codable` struct in Defaults v4 to `Codable` struct in Defaults v5

Before v4, `struct` have to conform to protocol `Codable` to store it as a JSON string.  

After v5, `struct` have to conform to protocol `Defaults.Serializable & Codable` to store it as a JSON string.  

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
1. Let `TimeZone` protocol conform to `Defaults.Serializable`.
```swift
private struct TimeZone: Defaults.Serializable & Codable {
	var id: String
	var name: String
}
```
2. Now `Defaults[.timezone]` should be readable.

---

### From `Codable` enum in Defaults v4 to `Codable` enum in Defaults v5

Before v4, `enum` have to conform to protocol `Codable` to store it as a JSON string.  

After v5, struct have to conform to protocol `Defaults.Serializable & Codable` to store it as a JSON string.  

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
1. Let `Period` protocol conform to `Defaults.Serializable`.
```swift
private enum Period: String, Defaults.Serializable & Codable {
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
1. Call `Defaults.migration(.arrayString)`, `Defaults.migration(.setString)`, `Defaults.migration(.dictionaryStringInt)`, `Defaults.migration(.dictionaryStringIntInArray)`.
2. Now `Defaults[.arrayString]`, `Defaults.[.setString]`, `Defaults[.dictionaryStringInt]`, `Defaults[.dictionaryStringIntInArray]` should be readable.

---

### From `Codable Array/Dictionary/Set` in Defaults v4 to `Native Array/Dictionary/Set`(With Codable Elements) in Defaults v5

Before v4, `Defaults` will store array/dictionary as a JSON string(`["{ "id": "0", "name": "Asia/Taipei" }"]`, `"10 Minutes"`).    

After v5, `Defaults` will store it as a native array/dictionary with codable elements(`[{ "id": "0", "name": "Asia/Taipei" }]`, `"10 Minutes"`).

#### Before migration, your code should be like this
```swift
private struct TimeZone: Codable & Hashable {
	var id: String
	var name: String
}
private enum Period: String, Codable & Hashable {
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
1. Let `TimeZone` and `Period` protocol conform to `Defaults.Serializable`
```swift
private struct TimeZone: Defaults.Serializable & Codable & Hashable {
	var id: String
	var name: String
}

private enum Period: String, Defaults.Serializable & Codable & Hashable {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}
```
2. Call `Defaults.migration(.arrayTimezone)`, `Defaults.migration(.setTimezone)`, `Defaults.migration(.dictionaryTimezone)`, `Defaults.migration(.arrayPeriod)`, `Defaults.migration(.setPeriod)` , `Defaults.migration(.dictionaryPeriod)`.
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
1. Create `CodablePeriod` and let its protocol conform to `Defaults.CodableType`
```swift
private enum CodablePeriod: String, Defaults.CodableType {
	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"

	/// Convert from `Codable` to `Native`
	func toNative() -> Period {
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
2. Let `Period` protocol conform to `Defaults.NativeType` and its `CodableForm` should be `CodablePeriod`
```swift
private enum Period: String, Defaults.NativeType {
	typealias CodableForm = CodablePeriod

	case tenMinutes = "10 Minutes"
	case halfHour = "30 Minutes"
	case oneHour = "1 Hour"
}
```
3. Call `Defaults.migration(.period)`
4. Now `Defaults[.period]` should be readable.


---

### From `Codable` struct in Defaults v4 to `Dictionary` in Defaults v5 (Optional) 

This situation happens when you have a struct which is stored as a codable JSON string before, but now you want it to be stored as a dictionary.

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
1. Create a `TimeZoneBridge` which protocol conform to `Defaults.Bridge` and its `Value` is TimeZone, `Serializable` is `[String: String]`.
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
2. Let `TimeZone` protocol conform to `Defaults.NativeType` and its static bridge is `TimeZoneBridge`(Compiler will complain that `TimeZone` is not conform to `Defaults.NativeType`, will resolve it later).
```swift
private struct TimeZone: Defaults.NativeType, Hashable {

	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}
```
3. Create `CodableTimeZone` and let it protocol conform to `Defaults.CodableType`
```swift
private struct CodableTimeZone: Defaults.CodableType {
	var id: String
	var name: String

	/// Convert from `Codable` to `Native`
	func toNative() -> TimeZone {
		TimeZone(id: id, name: name)
	}
}
```
4. Associate `TimeZone.CodableForm` to `CodableTimeZone`
```swift
private struct TimeZone: Defaults.NativeType, Hashable {
	/// Associated `CodableForm` to `CodableTimeZone`
	typealias CodableForm = CodableTimeZone

	var id: String
	var name: String

	static let bridge = TimeZoneBridge()
}
```
5. Call `Defaults.migration(.timezone)`, `Defaults.migration(.arrayTimezone)`, `Defaults.migration(.setTimezone)`, `Defaults.migration(.dictionaryTimezone)`.
6. Now `Defaults[.timezone]`, `Defaults[.arrayTimezone]` , `Defaults[.setTimezone]`, `Defaults[.dictionaryTimezone]` should be readable.

**See [DefaultsMigrationTests.swift](https://github.com/hank121314/Defaults/blob/develop/Tests/DefaultsTests/DefaultsMigrationTests.swift) for more example.**