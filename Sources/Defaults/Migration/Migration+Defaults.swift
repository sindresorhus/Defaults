import Foundation

extension Defaults {
	public enum Version: Int {
		case v5 = 5
	}

	/**
	Migrate the given key's value from JSON string to `Value`.

	```
	extension Defaults.Keys {
		static let array = Key<Set<String>?>("array")
	}

	Defaults.migrate(.array, to: .v5)
	```
	*/
	public static func migrate<Value: Defaults.Serializable & Codable>(_ keys: Key<Value>..., to version: Version) {
		migrate(keys, to: version)
	}

	public static func migrate<Value: Defaults.NativeType>(_ keys: Key<Value>..., to version: Version) {
		migrate(keys, to: version)
	}

	public static func migrate<Value: Defaults.Serializable & Codable>(_ keys: [Key<Value>], to version: Version) {
		switch version {
		case .v5:
			for key in keys {
				let suite = key.suite
				suite.migrateCodableToNative(forKey: key.name, of: Value.self)
			}
		}
	}

	public static func migrate<Value: Defaults.NativeType>(_ keys: [Key<Value>], to version: Version) {
		switch version {
		case .v5:
			for key in keys {
				let suite = key.suite
				suite.migrateCodableToNative(forKey: key.name, of: Value.self)
			}
		}
	}
}
