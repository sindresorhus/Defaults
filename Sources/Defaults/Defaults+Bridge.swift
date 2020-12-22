import Foundation

extension DefaultsCodableBridge {
	public func serialize(_ value: Value?) -> Serializable? {
		guard let value = value else {
			return nil
		}

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

	public func deserialize(_ object: Serializable?) -> Value? {
		guard let text = object,
					let data = "[\(text)]".data(using: .utf8)
		else {
			return nil
		}

		do {
			return (try JSONDecoder().decode([Value].self, from: data)).first
		} catch {
			print(error)
			return nil
		}
	}
}

extension Defaults {
	public struct TopLevelCodableBridge<Value: Codable>: Defaults.CodableBridge {}

	public struct RawRepresentableCodableBridge<Value>: CodableBridge where Value: RawRepresentable, Value: Codable {}

	public struct URLBridge: CodableBridge {
		public typealias Value = URL
	}

	public struct RawRepresentableBridge<Value: RawRepresentable>: Defaults.Bridge {
		public func serialize(_ value: Value?) -> Value.RawValue? {
			return value?.rawValue
		}

		public func deserialize(_ object: Value.RawValue?) -> Value? {
			guard let rawValue = object else {
				return nil
			}

			return Value(rawValue: rawValue)
		}
	}

	@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *)
	public struct NSSecureCodingBridge<Value: NSSecureCoding>: Defaults.Bridge {
		public func serialize(_ value: Value?) -> Data? {
			guard let object = value else {
				return nil
			}

			return try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true);
		}

		public func deserialize(_ object: Data?) -> Value? {
			guard let data = object else {
				return nil
			}

			do {
				return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Value
			} catch {
				print(error)
				return nil
			}
		}
	}

	public struct OptionalBridge<Bridge: Defaults.Bridge>: Defaults.Bridge {
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

	public struct DictionaryBridge<Value: Defaults.Serializable, Bridge: Defaults.Bridge>: Defaults.Bridge {
		public typealias Serializable = [String :Bridge.Serializable]

		private let bridge: Bridge

		init(bridge: Bridge) {
			self.bridge = bridge
		}

		public func serialize(_ value: Value?) -> Serializable? {
			guard let dictionary = value as? [String: Value.Property] else {
				return nil
			}

			return dictionary.reduce([:]) { (memo: Serializable, tuple: (key: String, value: Value.Property)) in
				var result = memo
				result[tuple.key] = bridge.serialize(tuple.value as? Bridge.Value)
				return result
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {

			return object?.reduce([:]) { (memo: [String: Value.Property], tuple: (key: String, value: Bridge.Serializable)) in
				var result = memo
				result[tuple.key] = bridge.deserialize(tuple.value) as? Value.Property
				return result
			} as? Value
		}
	}

	public struct ArrayBridge<Value: Defaults.Serializable, Bridge: Defaults.Bridge>: Defaults.Bridge {
		public typealias Serializable = [Bridge.Serializable]

		private let bridge: Bridge

		init(bridge: Bridge) {
			self.bridge = bridge
		}

		public func serialize(_ value: Value?) -> Serializable? {
			guard let array = value as? [Value.Property] else {
				return nil
			}

			return array.map({ bridge.serialize($0 as? Bridge.Value) }).compactMap { $0 }
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			object?.map({ bridge.deserialize($0) }).compactMap { $0 } as? Value
		}
	}
}
