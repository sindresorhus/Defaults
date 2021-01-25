import Foundation

extension UserDefaults {
	private func _get<Value: Defaults.Serializable>(_ key: String) -> Value? {
		let anyObject = object(forKey: key)

		if Value.isNativelySupportedType {
			// Return directly if anyObject can cast to Value
			if let anyObject = anyObject as? Value {
				return anyObject
			} else if let string = anyObject as? String {
				// Auto migration old codable value to native supported type.
				return _migration(string, key: key)
			}
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

		if Value.isNativelySupportedType {
			set(value, forKey: key)
		} else if let serialized = Value.bridge.serialize(value as? Value.Value) {
			set(serialized, forKey: key)
		}
	}

	private func _migration<Value: Defaults.Serializable>(_ value: String, key: String) -> Value? {
		guard
			let data = "[\(value)]".data(using: .utf8),
			let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [Value],
			let object = jsonObject.first
		else {
			return nil
		}

		_set(key, to: object)

		return object
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
