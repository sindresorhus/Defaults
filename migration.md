## Migration Guide From v4.X to v5.X

### From `Codable Array/Dictionary` to `Native Array/Dictionary/Set`(With Native Supported Elements)

Before v4.X, `Defaults` will store array/dictionary as a json string.  
After v5.X, `Defaults` will store it as a native array/dictionary with native supported elements.

Before all, your code should be like this
```swift
extension Defaults.Keys {
	static let arrayString = Defaults.Key<[String]?>("arrayString")
	static let dictionaryStringInt = Defaults.Key<[String: Int]?>("dictionaryStringInt")
}
```
#### Migration steps
1. Call `Defaults.migration(key)`.
2. Now `Defaults[arrayString]`, `Defaults[dictionaryStringInt]` should be readable.

### From `Codable Array/Dictionary` to `Native Array/Dictionary/Set`(With Codable Elements)

Before v4.X, `Defaults` will store array/dictionary as a json string.  
After v5.X, `Defaults` will store it as a native array/dictionary with codable elements.

Before all, your code should be like this
```swift
private struct TimeZone: Codable {
	var id: String
	var name: String
}

extension Defaults.Keys {
	static let arrayTimezone = Defaults.Key<[TimeZone]?>("arrayTimezone")
	static let dictionaryTimezone = Defaults.Key<[String: TimeZone]?>("dictionaryTimezone")
}
```
#### Migration steps
1. Let `TimeZone` protocol conform to `Defaults.Serializable`
```swift
private struct TimeZone: Defaults.Serializable & Codable {
	var id: String
	var name: String
}
```
1. Call `Defaults.migration(key)`.
3. Now `Defaults[arrayTimezone]`, `Defaults[dictionaryTimezone]` should be readable.


### From `Codable` struct to `Dictionary` (Optional) 

This situation happens when you have a struct which is stored as a codable json string before, but now you want it to be store as a dictionary.

Before all, your code should be like this
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
2. Let `TimeZone` protocol conform to `Defaults.NativeType` and its static bridge is `TimeZoneBridge`(Compiler will complain `TimeZone` is not conform to Defaults.NativeType now, will resolve it later).
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
5. Call `Defaults.migration(key)`.
6. Now `Defaults[timezone]`, `Defaults[arrayTimezone]` , `Defaults[setTimezone]`, `Defaults[dictionaryTimezone]` should be readable.

**See [DefaultsMigrationTests.swift](https://github.com/hank121314/Defaults/blob/develop/Tests/DefaultsTests/DefaultsMigrationTests.swift) for more example.**