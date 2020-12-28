import Foundation

extension UserDefaults {
	private func _get<Value: Defaults.NativelySupportedType>(_ key: String) -> Value? {
		guard let anyObject = object(forKey: key) else {
			return nil
		}

		// Return directly if anyObject can cast to Value
		if let value = anyObject as? Value {
			return value
		}

		// Auto migration old codable value to native supported type.
		return _migration(key, text: anyObject as? String)
	}

	private func _get<Value: Defaults.Serializable>(_ key: String) -> Value? {
		guard let anyObject = object(forKey: key) as? Value.Serializable else {
			return nil
		}

		return Value.bridge.deserialize(anyObject) as? Value
	}

	private func _set<Value: Defaults.NativelySupportedType>(_ key: String, to value: Value) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		set(value, forKey: key)
	}

	private func _set<Value: Defaults.Serializable>(_ key: String, to value: Value) {
		if (value as? _DefaultsOptionalType)?.isNil == true {
			removeObject(forKey: key)
			return
		}

		set(Value.bridge.serialize(value as? Value.Value), forKey: key)
	}

	private func _migration<Value: Defaults.NativelySupportedType>(_ key: String, text: String?) -> Value? {
		guard let value = [Value].init(jsonString: text)?.first else {
			return nil
		}

		_set(key, to: value)

		return value
	}

	public subscript<Value: Defaults.NativelySupportedType>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
		}
	}

	public subscript<Value: Defaults.Serializable>(key: Defaults.Key<Value>) -> Value {
		get { _get(key.name) ?? key.defaultValue }
		set {
			_set(key.name, to: newValue)
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
