import Foundation

extension Defaults {
	public static func migration<Value: Defaults.Serializable & Defaults.NativeType>(_ keys: Key<Value>...) {
		migration(keys)
	}

	/**
	Migration the given key's value from json string to `Value`.
	```
	extension Defaults.Keys {
		static let array = Key<Set<String>?>("array")
	}
	let text = "[\"a\", \"b\", \"c\"]"
	UserDefaults.standard.set(text, forKey: "array")

	UserDefaults.standard.string(forKey: keyName)
	//=> ["a","b","c"]

	Defaults.migration(.array)
	UserDefaults.standard.array(forKey: keyName)
	//=> [a, b, c, d]
	```
	*/
	public static func migration<Value: Defaults.Serializable & Defaults.NativeType>(_ keys: [Key<Value>]) {
		for key in keys {
			let suite = key.suite
			suite.migration(forKey: key.name, of: Value.self)
		}
	}
}
