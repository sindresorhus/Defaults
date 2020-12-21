import Foundation

public protocol DefaultsBridge {
	// The type of Value of Key<Value>
	associatedtype Value

	// This type should be one of the NativelySupportedType
	associatedtype Serializable

	// Serialize Value to Serializable before we store it in UserDefaults
	func serialize(_ value: Value?) -> Serializable?

	// Deserialize Serializable to Value
	func deserialize(_ object: Serializable?) -> Value?
}

public struct DefaultsURLBridge: DefaultsBridge {
	public func serialize(_ value: URL?) -> Any? {
		if let value = value {
			if #available(macOS 10.13, watchOS 4.0, macOSApplicationExtension 10.13, watchOSApplicationExtension 4.0, *) {
				let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
				return data
			}

			// If system is not support NSKeyedArchiver, we encode url to store in userDefaults
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

		return nil
	}

	public func deserialize(_ object: Any?) -> URL? {
		if let object = object as? URL {
			return object
		} else if let object = object as? String {
			guard let data = "[\(object)]".data(using: .utf8) else {
				return nil
			}
			do {
				return (try JSONDecoder().decode([Value].self, from: data)).first
			} catch {
				print(error)
			}
		} else if let object = object as? Data {
			if #available(macOS 10.13, watchOS 4.0, macOSApplicationExtension 10.13, watchOSApplicationExtension 4.0, *) {
				return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: object) as URL?
			} else {
				return NSKeyedUnarchiver.unarchiveObject(with: object) as? URL
			}
		}

		return nil
	}
}

public struct DefaultsRawRepresentableBridge<Value: RawRepresentable>: DefaultsBridge {
	public typealias Serializable = Value.RawValue
	public init() {}

	public func serialize(_ value: Value?) -> Serializable? {
		return value?.rawValue
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		if let rawValue = object {
			return Value(rawValue: rawValue)
		}

		return nil
	}
}

public struct DefaultsOptionalBridge<Bridge: DefaultsBridge>: DefaultsBridge {
	public typealias Value = Bridge.Value
	public typealias Serializable = Bridge.Serializable

	private let bridge: Bridge

	init(bridge: Bridge) {
		self.bridge = bridge
	}

	public func serialize(_ value: Value?) -> Serializable? {
		bridge.serialize(value)
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		bridge.deserialize(object)
	}
}

public struct DefaultsDictionaryBridge<Value: DefaultsSerializable, Bridge: DefaultsBridge>: DefaultsBridge {
	public typealias Value = Value
	public typealias Serializable = [String :Bridge.Serializable]

	private let bridge: Bridge

	init(bridge: Bridge) {
		self.bridge = bridge
	}

	public func serialize(_ value: Value?) -> Serializable? {
		if let value = value as? [String: Value.Property] {
			let value = value.reduce([:]) { (memo: Serializable, tuple: (key: String, value: Value.Property)) in
				var result = memo
				result[tuple.key] = bridge.serialize(tuple.value as? Bridge.Value)
				return result
			}
			return value
		}
		return nil
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		if let object = object {
			let object = object.reduce([:]) { (memo: [String: Value.Property], tuple: (key: String, value: Bridge.Serializable)) in
				var result = memo
				result[tuple.key] = bridge.deserialize(tuple.value) as? Value.Property
				return result
			}
			return object as? Value
		}
		return nil
	}
}

public struct DefaultsCollectionBridge<Value: DefaultsSerializable, Bridge: DefaultsBridge>: DefaultsBridge {
	public typealias Value = Value
	public typealias Serializable = [Bridge.Serializable]

	private let bridge: Bridge

	init(bridge: Bridge) {
		self.bridge = bridge
	}

	public func serialize(_ value: Value?) -> Serializable? {
		if let value = value as? [Value.Property] {
			let value = value.map({ bridge.serialize($0 as? Bridge.Value) }).compactMap { $0 }
			return value
		}

		return nil
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		if let object = object {
			return object.map({ bridge.deserialize($0) }).compactMap { $0 } as? Value
		}

		return nil
	}
}

public struct DefaultsCodableBridge<Value: Codable>: DefaultsBridge {
	public typealias Serializable = String
	public init() {}

	public func serialize(_ value: Value?) -> Serializable? {
		do {
			let data = try JSONEncoder().encode(value)
			return String(data: data, encoding: .utf8)
		} catch {
			print(error)
			return nil
		}
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		if let object = object {
			return Value.init(jsonString: object)
		}

		return nil
	}
}
