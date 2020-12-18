import Foundation

public struct DefaultsRawRepresentableBridge<Value: RawRepresentable>: DefaultsBridge {
	public typealias Serializable = Value.RawValue
	public init() {}

	public func serialize(_ value: Value?) -> Serializable? {
		return value?.rawValue
	}

	public func deserialize(_ object: Any) -> Value? {
		guard let rawValue = object as? Value.RawValue else { return nil }
		return Value(rawValue: rawValue)
	}
}

public struct DefaultsObjectBridge<Value: DefaultsSerializable>: DefaultsBridge {
	public init() {}

	public func serialize(_ value: Value?) -> Value? {
		return nil
	}

	public func deserialize(_ object: Any) -> Value? {
		return nil
	}
}

public struct DefaultsDictionaryBridge<Value: DefaultsSerializable>: DefaultsBridge {
	public init() {}

	public func serialize(_ value: Value?) -> Value? {
		return nil
	}

	public func deserialize(_ object: Any) -> Value? {
		return nil
	}
}

public struct DefaultsArrayBridge<Value: DefaultsSerializable>: DefaultsBridge {
	public init() {}

	public func serialize(_ value: Value?) -> Value? {
		return nil
	}

	public func deserialize(_ object: Any) -> Value? {
		return nil
	}
}

public struct DefaultsCodableBridge<Value: Codable>: DefaultsBridge {
	public typealias Serializable = String
	public init() {}

	public func serialize(_ value: Value?) -> Serializable? {
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

	public func deserialize(_ object: Any) -> Value? {
		return [Value].init(jsonString: "\(object)")?.first
	}
}

public struct DefaultsOptionalBridge<Bridge: DefaultsBridge>: DefaultsBridge {
	public typealias Value = Bridge.Value?
	public typealias Serializable = Bridge.Serializable?

	private let bridge: Bridge

	init(bridge: Bridge) {
		self.bridge = bridge
	}

	public func serialize(_ value: Bridge.Value??) -> Serializable? {
		bridge.serialize(value as? Bridge.Value)
	}

	public func deserialize(_ object: Any) -> Bridge.Value?? {
		bridge.deserialize(object)
	}
}
