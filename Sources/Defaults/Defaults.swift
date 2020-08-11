// MIT License © Sindre Sorhus
import Foundation

public protocol DefaultsBaseKey: Defaults.Keys {
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
	
	public class Keys: BaseKey {
		public typealias Key = Defaults.Key

		@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
		public typealias NSSecureCodingKey = Defaults.NSSecureCodingKey

		@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
		public typealias NSSecureCodingOptionalKey = Defaults.NSSecureCodingOptionalKey

		public let name: String
		public let suite: UserDefaults
		fileprivate init(name: String, suite: UserDefaults) {
			self.name = name
			self.suite = suite
		}
	}

	public final class Key<Value: Codable>: Keys {
		public let defaultValue: Value

		/// Create a defaults key.
		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
			self.defaultValue = defaultValue

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			if UserDefaults.isNativelySupportedType(Value.self) {
				suite.register(defaults: [key: defaultValue])
			} else if let value = suite._encode(defaultValue) {
				suite.register(defaults: [key: value])
			}
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public final class NSSecureCodingKey<Value: NSSecureCoding>: Keys {
		public let defaultValue: Value

		/// Create a defaults key.
		public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
			self.defaultValue = defaultValue

			super.init(name: key, suite: suite)

			if (defaultValue as? _DefaultsOptionalType)?.isNil == true {
				return
			}

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			if UserDefaults.isNativelySupportedType(Value.self) {
				suite.register(defaults: [key: defaultValue])
			} else if let value = try? NSKeyedArchiver.archivedData(withRootObject: defaultValue, requiringSecureCoding: true) {
				suite.register(defaults: [key: value])
			}
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public final class NSSecureCodingOptionalKey<Value: NSSecureCoding>: Keys {
		/// Create an optional defaults key.
		public init(_ key: String, suite: UserDefaults = .standard) {
			super.init(name: key, suite: suite)
		}
	}

	/// Access a defaults value using a `Defaults.Key`.
	public static subscript<Value: Codable>(key: Key<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	/// Access a defaults value using a `Defaults.NSSecureCodingKey`.
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static subscript<Value: NSSecureCoding>(key: NSSecureCodingKey<Value>) -> Value {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	/// Access a defaults value using a `Defaults.NSSecureCodingOptionalKey`.
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static subscript<Value: NSSecureCoding>(key: NSSecureCodingOptionalKey<Value>) -> Value? {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}
}

extension Defaults {
	/**
	Remove all entries from the given `UserDefaults` suite.
	*/
	public static func removeAll(suite: UserDefaults = .standard) {
		for key in suite.dictionaryRepresentation().keys {
			suite.removeObject(forKey: key)
		}
	}
}

extension Defaults.Key where Value: _DefaultsOptionalType {
	public convenience init(_ key: String, suite: UserDefaults = .standard) {
		self.init(key, default: nil, suite: suite)
	}
}

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
extension Defaults.NSSecureCodingKey where Value: _DefaultsOptionalType {
	public convenience init(_ key: String, suite: UserDefaults = .standard) {
		self.init(key, default: nil, suite: suite)
	}
}
