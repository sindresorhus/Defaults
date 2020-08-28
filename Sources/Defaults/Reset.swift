import Foundation

extension Defaults {
	/**
	Reset the given string keys back to their default values.

	Prefer using the strongly-typed keys instead whenever possible. This method can be useful if you need to store some keys in a collection, as it's not possible to store `Defaults.Key` in a collection because it's generic.

	- Parameter keys: String keys to reset.
	- Parameter suite: `UserDefaults` suite.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	Defaults[.isUnicornMode] = true
	//=> true

	Defaults.reset(Defaults.Keys.isUnicornMode.name)
	// Or `Defaults.reset("isUnicornMode")`

	Defaults[.isUnicornMode]
	//=> false
	```
	*/
	public static func reset(_ keys: String..., suite: UserDefaults = .standard) {
		reset(keys, suite: suite)
	}

	/**
	Reset the given string keys back to their default values.

	Prefer using the strongly-typed keys instead whenever possible. This method can be useful if you need to store some keys in a collection, as it's not possible to store `Defaults.Key` in a collection because it's generic.

	- Parameter keys: String keys to reset.
	- Parameter suite: `UserDefaults` suite.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	Defaults[.isUnicornMode] = true
	//=> true

	Defaults.reset([Defaults.Keys.isUnicornMode.name])
	// Or `Defaults.reset(["isUnicornMode"])`

	Defaults[.isUnicornMode]
	//=> false
	```
	*/
	public static func reset(_ keys: [String], suite: UserDefaults = .standard) {
		for key in keys {
			suite.removeObject(forKey: key)
		}
	}
}

extension Defaults {
	/**
	Reset the given keys back to their default values.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	Defaults[.isUnicornMode] = true
	//=> true

	Defaults.reset(.isUnicornMode)

	Defaults[.isUnicornMode]
	//=> false
	```
	*/
	public static func reset(_ keys: AnyKey...) {
		reset(keys)
	}

	/**
	Reset the given keys back to their default values.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	Defaults[.isUnicornMode] = true
	//=> true

	Defaults.reset(.isUnicornMode)

	Defaults[.isUnicornMode]
	//=> false
	```
	*/
	public static func reset(_ keys: [AnyKey]) {
		for key in keys {
			key.reset()
		}
	}
}
