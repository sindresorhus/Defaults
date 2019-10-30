// MIT License © Sindre Sorhus
import Foundation

public final class Defaults {
	public class Keys {
		public typealias Key = Defaults.Key

		@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
		public typealias NSSecureCodingKey = Defaults.NSSecureCodingKey

		public typealias OptionalKey = Defaults.OptionalKey

		@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
		public typealias NSSecureCodingOptionalKey = Defaults.NSSecureCodingOptionalKey

		fileprivate init() {}
	}

	public final class Key<T: Codable>: Keys {
		public let name: String
		public let defaultValue: T
		public let suite: UserDefaults

		/// Create a defaults key.
		public init(_ key: String, default defaultValue: T, suite: UserDefaults = .standard) {
			self.name = key
			self.defaultValue = defaultValue
			self.suite = suite

			super.init()

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			if UserDefaults.isNativelySupportedType(T.self) {
				suite.register(defaults: [key: defaultValue])
			} else if let value = suite._encode(defaultValue) {
				suite.register(defaults: [key: value])
			}
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public final class NSSecureCodingKey<T: NSSecureCoding>: Keys {
		public let name: String
		public let defaultValue: T
		public let suite: UserDefaults

		/// Create a defaults key.
		public init(_ key: String, default defaultValue: T, suite: UserDefaults = .standard) {
			self.name = key
			self.defaultValue = defaultValue
			self.suite = suite

			super.init()

			// Sets the default value in the actual UserDefaults, so it can be used in other contexts, like binding.
			if UserDefaults.isNativelySupportedType(T.self) {
				suite.register(defaults: [key: defaultValue])
			} else if let value = try? NSKeyedArchiver.archivedData(withRootObject: defaultValue, requiringSecureCoding: true) {
				suite.register(defaults: [key: value])
			}
		}
	}

	public final class OptionalKey<T: Codable>: Keys {
		public let name: String
		public let suite: UserDefaults

		/// Create an optional defaults key.
		public init(_ key: String, suite: UserDefaults = .standard) {
			self.name = key
			self.suite = suite
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public final class NSSecureCodingOptionalKey<T: NSSecureCoding>: Keys {
		public let name: String
		public let suite: UserDefaults

		/// Create an optional defaults key.
		public init(_ key: String, suite: UserDefaults = .standard) {
			self.name = key
			self.suite = suite
		}
	}

	fileprivate init() {}

	/// Access a defaults value using a `Defaults.Key`.
	public static subscript<T: Codable>(key: Key<T>) -> T {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	/// Access a defaults value using a `Defaults.NSSecureCodingKey`.
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static subscript<T: NSSecureCoding>(key: NSSecureCodingKey<T>) -> T {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	/// Access a defaults value using a `Defaults.OptionalKey`.
	public static subscript<T: Codable>(key: OptionalKey<T>) -> T? {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}

	/// Access a defaults value using a `Defaults.OptionalKey`.
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static subscript<T: NSSecureCoding>(key: NSSecureCodingOptionalKey<T>) -> T? {
		get { key.suite[key] }
		set {
			key.suite[key] = newValue
		}
	}
	
	/**
	Reset the given keys back to their default values.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.

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
	public static func reset<T: Codable>(_ keys: Key<T>..., suite: UserDefaults = .standard) {
		reset(keys, suite: suite)
	}

	/**
	Reset the given keys back to their default values.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<T: NSSecureCoding>(_ keys: NSSecureCodingKey<T>..., suite: UserDefaults = .standard) {
		reset(keys, suite: suite)
	}
	
	/**
	Reset the given array of keys back to their default values.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.

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
	public static func reset<T: Codable>(_ keys: [Key<T>], suite: UserDefaults = .standard) {
		for key in keys {
			key.suite[key] = key.defaultValue
		}
	}

	/**
	Reset the given array of keys back to their default values.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<T: NSSecureCoding>(_ keys: [NSSecureCodingKey<T>], suite: UserDefaults = .standard) {
		for key in keys {
			key.suite[key] = key.defaultValue
		}
	}
	
	/**
	Reset the given optional keys back to `nil`.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.

	```
	extension Defaults.Keys {
		static let unicorn = OptionalKey<String>("unicorn")
	}

	Defaults[.unicorn] = "🦄"

	Defaults.reset(.unicorn)

	Defaults[.unicorn]
	//=> nil
	```
	*/
	public static func reset<T: Codable>(_ keys: OptionalKey<T>..., suite: UserDefaults = .standard) {
		reset(keys, suite: suite)
	}

	/**
	Reset the given optional keys back to `nil`.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.
	```
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<T: NSSecureCoding>(_ keys: NSSecureCodingOptionalKey<T>..., suite: UserDefaults = .standard) {
		reset(keys, suite: suite)
	}
	
	/**
	Reset the given array of optional keys back to `nil`.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.

	```
	extension Defaults.Keys {
		static let unicorn = OptionalKey<String>("unicorn")
	}

	Defaults[.unicorn] = "🦄"

	Defaults.reset(.unicorn)

	Defaults[.unicorn]
	//=> nil
	```
	*/
	public static func reset<T: Codable>(_ keys: [OptionalKey<T>], suite: UserDefaults = .standard) {
		for key in keys {
			key.suite[key] = nil
		}
	}

	/**
	Reset the given array of optional keys back to `nil`.

	- Parameter keys: Keys to reset.
	- Parameter suite: `UserDefaults` suite.
	*/
	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public static func reset<T: NSSecureCoding>(_ keys: [NSSecureCodingOptionalKey<T>], suite: UserDefaults = .standard) {
		for key in keys {
			key.suite[key] = nil
		}
	}

	/**
	Remove all entries from the `UserDefaults` suite.
	*/
	public static func removeAll(suite: UserDefaults = .standard) {
		for key in suite.dictionaryRepresentation().keys {
			suite.removeObject(forKey: key)
		}
	}
}

extension UserDefaults {
	private func _get<T: Codable>(_ key: String) -> T? {
		if UserDefaults.isNativelySupportedType(T.self) {
			return object(forKey: key) as? T
		}

		guard
			let text = string(forKey: key),
			let data = "[\(text)]".data(using: .utf8)
		else {
			return nil
		}

		do {
			return (try JSONDecoder().decode([T].self, from: data)).first
		} catch {
			print(error)
		}

		return nil
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	private func _get<T: NSSecureCoding>(_ key: String) -> T? {
		if UserDefaults.isNativelySupportedType(T.self) {
			return object(forKey: key) as? T
		}

		guard
			let data = data(forKey: key)
		else {
			return nil
		}

		do {
			return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
		} catch {
			print(error)
		}

		return nil
	}

	fileprivate func _encode<T: Codable>(_ value: T) -> String? {
		do {
			// Some codable values like URL and enum are encoded as a top-level
			// string which JSON can't handle, so we need to wrap it in an array
			// We need this: https://forums.swift.org/t/allowing-top-level-fragments-in-jsondecoder/11750
			let data = try JSONEncoder().encode([value])
			return String(String(data: data, encoding: .utf8)!.dropFirst().dropLast())
		} catch {
			print(error)
			return nil
		}
	}

	private func _set<T: Codable>(_ key: String, to value: T) {
		if UserDefaults.isNativelySupportedType(T.self) {
			set(value, forKey: key)
			return
		}

		set(_encode(value), forKey: key)
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	private func _set<T: NSSecureCoding>(_ key: String, to value: T) {
		if UserDefaults.isNativelySupportedType(T.self) {
			set(value, forKey: key)
			return
		}

		set(try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true), forKey: key)
	}

	public subscript<T: Codable>(key: Defaults.Key<T>) -> T {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public subscript<T: NSSecureCoding>(key: Defaults.NSSecureCodingKey<T>) -> T {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	public subscript<T: Codable>(key: Defaults.OptionalKey<T>) -> T? {
		get { _get(key.name) }
		set {
			guard let value = newValue else {
				set(nil, forKey: key.name)
				return
			}

			_set(key.name, to: value)
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public subscript<T: NSSecureCoding>(key: Defaults.NSSecureCodingOptionalKey<T>) -> T? {
		get { _get(key.name) }
		set {
			guard let value = newValue else {
				set(nil, forKey: key.name)
				return
			}

			_set(key.name, to: value)
		}
	}

	fileprivate static func isNativelySupportedType<T>(_ type: T.Type) -> Bool {
		switch type {
		case is Bool.Type,
			 is String.Type,
			 is Int.Type,
			 is Double.Type,
			 is Float.Type,
			 is Date.Type,
			 is Data.Type:
			return true
		default:
			return false
		}
	}
}
