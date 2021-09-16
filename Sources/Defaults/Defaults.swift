// MIT License © Sindre Sorhus
import Foundation

public protocol DefaultsBaseKey: Defaults.AnyKey {
	var name: String { get }
	var suite: UserDefaults { get }
}

extension DefaultsBaseKey {
	/// Reset the item back to its default value.
	public func reset() {
		suite.removeObject(forKey: name)
	}
}

public enum Defaults {
	public typealias BaseKey = DefaultsBaseKey
	public typealias AnyKey = Keys
	public typealias Serializable = DefaultsSerializable
	public typealias CollectionSerializable = DefaultsCollectionSerializable
	public typealias SetAlgebraSerializable = DefaultsSetAlgebraSerializable
	public typealias Bridge = DefaultsBridge

	public class Keys: BaseKey {
		public typealias Key = Defaults.Key

		public let name: String
		public let suite: UserDefaults

		fileprivate init(name: String, suite: UserDefaults) {
			self.name = name
			self.suite = suite
		}
	}

	public final class Key<Value: Serializable>: AnyKey {
		public let defaultValue: Value
		/// A flag to determine whether CodableBridge is a first-class serializator
		var usingCodable = true

		/// Create a defaults key.
		/// The `default` parameter can be left out if the `Value` type is an optional.
		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard, usingCodable: Bool = true) {
			self.defaultValue = defaultValue
			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			guard let serialized = Value.toSerializable(defaultValue) else {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			suite.register(defaults: [name: serialized])
		}

		/// When Value conforms to `Codable` we should use `toCodableSerializable` to serialize it.
		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard, usingCodable: Bool = true) where Value: Codable {
			self.defaultValue = defaultValue
			self.usingCodable = usingCodable

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			guard let serialized = Value.toCodableSerializable(defaultValue, usingCodable: self.usingCodable) else {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			suite.register(defaults: [name: serialized])
		}
	}

	public static subscript<Value: Serializable>(key: Key<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	public static subscript<Value: Serializable & Codable>(key: Key<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}
}

extension Defaults {
	/**
	Remove all entries from the given `UserDefaults` suite.

	- Note: This only removes user-defined entries. System-defined entries will remain.
	*/
	public static func removeAll(suite: UserDefaults = .standard) {
		suite.removeAll()
	}
}

extension Defaults.Key {
	public convenience init<T: Defaults.Serializable>(_ key: String, suite: UserDefaults = .standard, usingCodable: Bool = true) where Value == T? {
		self.init(key, default: nil, suite: suite)
	}

	public convenience init<T: Defaults.Serializable & Codable>(_ key: String, suite: UserDefaults = .standard, usingCodable: Bool = true) where Value == T? {
		self.init(key, default: nil, suite: suite, usingCodable: usingCodable)
	}
}
