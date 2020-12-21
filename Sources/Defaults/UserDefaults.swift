import Foundation

extension UserDefaults {
	private func _get<Value: DefaultsSerializable>(_ key: String) -> Value? {
		if let any_object = object(forKey: key) {
			if UserDefaults.isNativelySupportedType(Value.Property.self) {
				return any_object as? Value
			} else if let value = Value.bridge.deserialize(any_object as? Value.Serializable) {
				return value as? Value
			}
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

	private func _set<Value: DefaultsSerializable>(_ key: String, to value: Value) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		if UserDefaults.isNativelySupportedType(Value.Property.self) {
			set(value, forKey: key)
			return
		}
		
		set(Value.bridge.serialize(value as? Value.Value), forKey: key)
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

	public subscript<Value: DefaultsSerializable>(key: Defaults.Key<Value>) -> Value {
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
			is Data?.Type,
			is URL.Type,
			is URL?.Type:
			return true
		default:
			return false
		}
	}

	static func isNativelySupportedType<T: NativelySupportedType>(_ type: T.Type) -> Bool {
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
		case
			is [String: T.Property].Type,
			is [String: T.Property]?.Type,
			is [T.Property].Type,
			is [T.Property]?.Type:
			return isNativelySupportedType(T.Property.self)
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
