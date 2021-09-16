import Foundation

extension UserDefaults {
	func _get<Value: Defaults.Serializable>(_ key: String) -> Value? {
		guard let anyObject = object(forKey: key) else {
			return nil
		}

		return Value.toValue(anyObject)
	}

	func _get<Value: Defaults.Serializable & Codable>(_ key: String, usingCodable: Bool) -> Value? {
		guard let anyObject = object(forKey: key) else {
			return nil
		}

		return Value.toCodableValue(anyObject, usingCodable: usingCodable)
	}

	func _set<Value: Defaults.Serializable>(_ key: String, to value: Value) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		set(Value.toSerializable(value), forKey: key)
	}

	func _set<Value: Defaults.Serializable & Codable>(_ key: String, to value: Value, usingCodable: Bool) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		set(Value.toCodableSerializable(value, usingCodable: usingCodable), forKey: key)
	}

	public subscript<Value: Defaults.Serializable>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	public subscript<Value: Defaults.Serializable & Codable>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name, usingCodable: key.usingCodable) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue, usingCodable: key.usingCodable)
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
