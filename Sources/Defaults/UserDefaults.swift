import Foundation

extension UserDefaults {
	private func _get<Value: Codable>(_ key: String) -> Value? {
		if UserDefaults.isNativelySupportedType(Value.self) {
			return object(forKey: key) as? Value
		}

		guard
			let text = string(forKey: key),
			let data = "[\(text)]".data(using: .utf8)
		else {
			return nil
		}

		do {
			return (try JSONDecoder().decode([Value].self, from: data)).first
		} catch {
			print(error)
		}

		return nil
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	private func _get<Value: NSSecureCoding>(_ key: String) -> Value? {
		if UserDefaults.isNativelySupportedType(Value.self) {
			return object(forKey: key) as? Value
		}

		guard
			let data = data(forKey: key)
		else {
			return nil
		}

		do {
			return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Value
		} catch {
			print(error)
		}

		return nil
	}

	func _encode<Value: Codable>(_ value: Value) -> String? {
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

	private func _set<Value: Codable>(_ key: String, to value: Value) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		if UserDefaults.isNativelySupportedType(Value.self) {
			set(value, forKey: key)
			return
		}

		set(_encode(value), forKey: key)
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	private func _set<Value: NSSecureCoding>(_ key: String, to value: Value) {
		// TODO: Handle nil here too.
		if UserDefaults.isNativelySupportedType(Value.self) {
			set(value, forKey: key)
			return
		}

		set(try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true), forKey: key)
	}

	public subscript<Value>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public subscript<Value>(key: Defaults.NSSecureCodingKey<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public subscript<Value>(key: Defaults.NSSecureCodingOptionalKey<Value>) -> Value? {
		get { _get(key.name) }
		set {
			guard let value = newValue else {
				set(nil, forKey: key.name)
				return
			}

			_set(key.name, to: value)
		}
	}

	static func isNativelySupportedType<T>(_ type: T.Type) -> Bool {
		switch type {
		case
			is Bool.Type,
			is Bool?.Type, // swiftlint:disable:this discouraged_optional_boolean
			is String.Type,
			is String?.Type,
			is Int.Type,
			is Int?.Type,
			is Double.Type,
			is Double?.Type,
			is Float.Type,
			is Float?.Type,
			is Date.Type,
			is Date?.Type,
			is Data.Type,
			is Data?.Type:
			return true
		default:
			return false
		}
	}
}

extension UserDefaults {
	/**
	Remove all entries.

	- Note: This only removes user-defined entries. System-defined entries will remain.
	*/
	public func removeAll() {
		// We're not using `.removePersistentDomain(forName:)` as it requires knowing the suite name and also because it doesn't emit change events for each key, but rather just `UserDefaults.didChangeNotification`, which we don't subscribe to.
		for key in dictionaryRepresentation().keys {
			removeObject(forKey: key)
		}
	}
}
