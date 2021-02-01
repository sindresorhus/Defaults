import Foundation

extension Defaults {
	public static func migration<Value: Defaults.Serializable & Defaults.NativeType>(_ keys: Key<Value>...) {
		migration(keys)
	}

	public static func migration<Value: Defaults.Serializable & Defaults.NativeType>(_ keys: [Key<Value>]) {
		for key in keys {
			let suite = key.suite
			suite.migration(forKey: key.name, of: Value.self)
		}
	}
}
