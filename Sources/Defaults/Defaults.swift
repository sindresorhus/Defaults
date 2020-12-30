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
	public typealias Bridge = DefaultsBridge
	public typealias CodableBridge = DefaultsCodableBridge
	public typealias NativelySupportedType = DefaultsNativelySupportedType

	public class Keys: BaseKey {
		public typealias Key = Defaults.Key

		public let name: String
		public let suite: UserDefaults

		fileprivate init(name: String, suite: UserDefaults) {
			self.name = name
			self.suite = suite
		}
	}

	public final class Key<Value>: AnyKey {
		public let defaultValue: Value

		/// Create a defaults key.
		/// The `default` parameter can be left out if the `Value` type is an optional.
		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) where Value: NativelySupportedType {
			self.defaultValue = defaultValue

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			suite.register(defaults: [key: defaultValue])
		}

		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) where Value: Serializable {
			self.defaultValue = defaultValue

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			guard let value = Value.bridge.serialize(defaultValue as? Value.Value) else {
				return
			}

			suite.register(defaults: [key: value])
		}
	}

	/// Access a defaults value using a `Defaults.Key`.
	public static subscript<Value: NativelySupportedType>(key: Key<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	public static subscript<Value: Serializable>(key: Key<Value>) -> Value {
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
	public convenience init<T: Defaults.NativelySupportedType>(_ key: String, suite: UserDefaults = .standard) where Value == T? {
		self.init(key, default: nil, suite: suite)
	}

	public convenience init<T: Defaults.Serializable>(_ key: String, suite: UserDefaults = .standard) where Value == T? {
		self.init(key, default: nil, suite: suite)
	}
}
