import Foundation

extension UserDefaults {
	func _get<Value: Defaults.Serializable>(_ key: String) -> Value? {
		guard let anyObject = object(forKey: key) else {
			return nil
		}

		return Value.toValue(anyObject)
	}

	func _set<Value: Defaults.Serializable>(_ key: String, to value: Value) {
		if (value as? (any _DefaultsOptionalProtocol))?._defaults_isNil == true {
			removeObject(forKey: key)
			return
		}

		set(Value.toSerializable(value), forKey: key)
	}

	public subscript<Value: Defaults.Serializable>(key: Defaults.Key<Value>) -> Value {
		get {
			if key.usesExternalStorage {
				return Defaults.ExternalStorage.lock(for: key.name).with {
					guard let fileID: String = _get(key.name) else {
						return key.defaultValue
					}

					return Defaults.ExternalStorage.load(
						fileID: fileID,
						forKey: key.name,
						defaultValue: key.defaultValue,
						suite: self
					)
				}
			}

			return _get(key.name) ?? key.defaultValue
		}
		set {
			if key.usesExternalStorage {
				// Use per-key lock to prevent concurrent access issues
				Defaults.ExternalStorage.lock(for: key.name).with {
					// Handle nil values
					if (newValue as? (any _DefaultsOptionalProtocol))?._defaults_isNil == true {
						// Clean up old external file if it exists
						if let oldFileID: String = _get(key.name) {
							Defaults.ExternalStorage.delete(fileID: oldFileID, forKey: key.name)
						}

						removeObject(forKey: key.name)
					} else {
						do {
							// Save new file first (with new UUID) before deleting old file
							// This prevents data loss if app crashes during the operation
							let newFileID = try Defaults.ExternalStorage.save(newValue, forKey: key.name)

							// Get old file ID before updating UserDefaults
							let oldFileID: String? = _get(key.name)

							// Update UserDefaults with new file ID
							_set(key.name, to: newFileID)

							// Now safe to delete old file - if this fails, we just have an orphaned file which is better than losing data
							if let oldFileID = oldFileID {
								Defaults.ExternalStorage.delete(fileID: oldFileID, forKey: key.name)
							}
						} catch {
							runtimeWarn(false, "Failed to save external storage for '\(key.name)': \(error)")
							// Keep existing value and reference on failure - do not nuke the old value
						}
					}
				}

				return
			}

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

		for (key, value) in dictionaryRepresentation() {
			// Check if this might be an external storage reference (UUID string)
			if
				let stringValue = value as? String,
				UUID(uuidString: stringValue) != nil
			{
				// Acquire per-key lock to prevent race with concurrent writes
				Defaults.ExternalStorage.lock(for: key).with {
					// Re-read inside lock to ensure consistency
					if let currentFileID = string(forKey: key) {
						Defaults.ExternalStorage.delete(fileID: currentFileID, forKey: key)
					}

					removeObject(forKey: key)
				}
			} else {
				removeObject(forKey: key)
			}
		}
	}
}
