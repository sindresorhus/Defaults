import Foundation

/*
TODO: When Swift gets support for static key paths, all of this could be simplified to just:

```
extension Defaults {
	public static func reset(_ keys: KeyPath<Keys, _DefaultsBaseKey>...) {
		for key in keys {
			Keys[keyPath: key].reset()
		}
	}
}
```
*/

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

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable
	>(
		_ key1: Key<Value1>
	) {
		key1.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>
	) {
		key1.reset()
		key2.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable,
		Value6: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>,
		_ key6: Key<Value6>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable,
		Value6: Codable,
		Value7: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>,
		_ key6: Key<Value6>,
		_ key7: Key<Value7>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable,
		Value6: Codable,
		Value7: Codable,
		Value8: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>,
		_ key6: Key<Value6>,
		_ key7: Key<Value7>,
		_ key8: Key<Value8>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable,
		Value6: Codable,
		Value7: Codable,
		Value8: Codable,
		Value9: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>,
		_ key6: Key<Value6>,
		_ key7: Key<Value7>,
		_ key8: Key<Value8>,
		_ key9: Key<Value9>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.

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
	public static func reset<
		Value1: Codable,
		Value2: Codable,
		Value3: Codable,
		Value4: Codable,
		Value5: Codable,
		Value6: Codable,
		Value7: Codable,
		Value8: Codable,
		Value9: Codable,
		Value10: Codable
	>(
		_ key1: Key<Value1>,
		_ key2: Key<Value2>,
		_ key3: Key<Value3>,
		_ key4: Key<Value4>,
		_ key5: Key<Value5>,
		_ key6: Key<Value6>,
		_ key7: Key<Value7>,
		_ key8: Key<Value8>,
		_ key9: Key<Value9>,
		_ key10: Key<Value10>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
		key10.reset()
	}
}

extension Defaults {
	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>
	) {
		key1.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>
	) {
		key1.reset()
		key2.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>,
		_ key6: NSSecureCodingKey<Value6>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>,
		_ key6: NSSecureCodingKey<Value6>,
		_ key7: NSSecureCodingKey<Value7>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>,
		_ key6: NSSecureCodingKey<Value6>,
		_ key7: NSSecureCodingKey<Value7>,
		_ key8: NSSecureCodingKey<Value8>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding,
		Value9: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>,
		_ key6: NSSecureCodingKey<Value6>,
		_ key7: NSSecureCodingKey<Value7>,
		_ key8: NSSecureCodingKey<Value8>,
		_ key9: NSSecureCodingKey<Value9>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding,
		Value9: NSSecureCoding,
		Value10: NSSecureCoding
	>(
		_ key1: NSSecureCodingKey<Value1>,
		_ key2: NSSecureCodingKey<Value2>,
		_ key3: NSSecureCodingKey<Value3>,
		_ key4: NSSecureCodingKey<Value4>,
		_ key5: NSSecureCodingKey<Value5>,
		_ key6: NSSecureCodingKey<Value6>,
		_ key7: NSSecureCodingKey<Value7>,
		_ key8: NSSecureCodingKey<Value8>,
		_ key9: NSSecureCodingKey<Value9>,
		_ key10: NSSecureCodingKey<Value10>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
		key10.reset()
	}
}

extension Defaults {
	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>
	) {
		key1.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>
	) {
		key1.reset()
		key2.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>,
		_ key6: NSSecureCodingOptionalKey<Value6>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>,
		_ key6: NSSecureCodingOptionalKey<Value6>,
		_ key7: NSSecureCodingOptionalKey<Value7>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>,
		_ key6: NSSecureCodingOptionalKey<Value6>,
		_ key7: NSSecureCodingOptionalKey<Value7>,
		_ key8: NSSecureCodingOptionalKey<Value8>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding,
		Value9: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>,
		_ key6: NSSecureCodingOptionalKey<Value6>,
		_ key7: NSSecureCodingOptionalKey<Value7>,
		_ key8: NSSecureCodingOptionalKey<Value8>,
		_ key9: NSSecureCodingOptionalKey<Value9>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
	}

	/**
	Reset the given keys back to their default values.

	You can specify up to 10 keys. If you need to specify more, call this method multiple times.

	The 10 limit is a Swift generics limitation. If you really want, you could specify more overloads.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<
		Value1: NSSecureCoding,
		Value2: NSSecureCoding,
		Value3: NSSecureCoding,
		Value4: NSSecureCoding,
		Value5: NSSecureCoding,
		Value6: NSSecureCoding,
		Value7: NSSecureCoding,
		Value8: NSSecureCoding,
		Value9: NSSecureCoding,
		Value10: NSSecureCoding
	>(
		_ key1: NSSecureCodingOptionalKey<Value1>,
		_ key2: NSSecureCodingOptionalKey<Value2>,
		_ key3: NSSecureCodingOptionalKey<Value3>,
		_ key4: NSSecureCodingOptionalKey<Value4>,
		_ key5: NSSecureCodingOptionalKey<Value5>,
		_ key6: NSSecureCodingOptionalKey<Value6>,
		_ key7: NSSecureCodingOptionalKey<Value7>,
		_ key8: NSSecureCodingOptionalKey<Value8>,
		_ key9: NSSecureCodingOptionalKey<Value9>,
		_ key10: NSSecureCodingOptionalKey<Value10>
	) {
		key1.reset()
		key2.reset()
		key3.reset()
		key4.reset()
		key5.reset()
		key6.reset()
		key7.reset()
		key8.reset()
		key9.reset()
		key10.reset()
	}
}
