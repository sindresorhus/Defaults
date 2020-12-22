import Foundation

extension UserDefaults {
	private func _get<Value: Defaults.Serializable>(_ key: String) -> Value? {
		guard let anyObject = object(forKey: key) else {
			return nil
		}

		if UserDefaults.isNativelySupportedType(Value.Property.self) {
			return anyObject as? Value
		} else if let value = Value.bridge.deserialize(anyObject as? Value.Serializable) {
			return value as? Value
		}

		return nil
	}

	private func _set<Value: Defaults.Serializable>(_ key: String, to value: Value) {
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

	public subscript<Value: Defaults.Serializable>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	static func isNativelySupportedType<T: Defaults.NativelySupportedType>(_ type: T.Type) -> Bool {
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
			is CGFloat.Type,
			is CGFloat?.Type,
			is Int8.Type,
			is Int8?.Type,
			is UInt8.Type,
			is UInt8?.Type,
			is Int16.Type,
			is Int16?.Type,
			is UInt16.Type,
			is UInt16?.Type,
			is Int32.Type,
			is Int32?.Type,
			is UInt32.Type,
			is UInt32?.Type,
			is Int64.Type,
			is Int64?.Type,
			is UInt64.Type,
			is UInt64?.Type:
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
