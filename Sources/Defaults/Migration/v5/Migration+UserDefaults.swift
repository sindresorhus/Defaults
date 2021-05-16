import Foundation

extension UserDefaults {
	func migrateCodableToNative<Value: Defaults.Serializable & Codable>(forKey key: String, of type: Value.Type) {
		guard
			let jsonString = string(forKey: key),
			let jsonData = jsonString.data(using: .utf8),
			let codable = try? JSONDecoder().decode(Value.self, from: jsonData)
		else {
			return
		}

		_set(key, to: codable)
	}

	/**
	Get a JSON string in `UserDefaults` and decode it into its `NativeForm`.

	How does it work?

	1. If `Value` is  `[String]`, `Value.CodableForm` will covert into `[String].CodableForm`.

	```
	JSONDecoder().decode([String].CodableForm.self, from: jsonData)
	```

	2. If `Array` conforms to `NativeType`, its `CodableForm` is `[Element.CodableForm]` and `Element` is `String`.

	```
	JSONDecoder().decode([String.CodableForm].self, from: jsonData)
	```

	3. `String`'s `CodableForm` is `self`,  because `String` is `Codable`.

	```
	JSONDecoder().decode([String].self, from: jsonData)
	```
	*/
	func migrateCodableToNative<Value: Defaults.NativeType>(forKey key: String, of type: Value.Type) {
		guard
			let jsonString = string(forKey: key),
			let jsonData = jsonString.data(using: .utf8),
			let codable = try? JSONDecoder().decode(Value.CodableForm.self, from: jsonData)
		else {
			return
		}

		_set(key, to: codable.toNative())
	}
}
