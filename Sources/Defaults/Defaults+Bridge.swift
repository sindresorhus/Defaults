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
		guard let value = [Value].init(jsonString: object)?.first else {
			return nil
		}

		return value
	}
}

extension Defaults {
	public struct TopLevelCodableBridge<Value: Codable>: CodableBridge {}

	// RawRepresentableCodableBridge is indeed because if `enum SomeEnum: String, Codable, Defaults.Serializable` the compiler will confuse between RawRepresentableBridge and TopLevelCodableBridge
	public struct RawRepresentableCodableBridge<Value>: CodableBridge where Value: RawRepresentable & Codable {}

	public struct URLBridge: CodableBridge {
		public typealias Value = URL
	}

	public struct RawRepresentableBridge<Value: RawRepresentable>: Bridge {
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
		public typealias Serializable = [String: Bridge.Serializable]

		private let bridge: Bridge

		init(bridge: Bridge) {
			self.bridge = bridge
		}

		public func serialize(_ value: Value?) -> Serializable? {
			guard let dictionary = value as? [String: Bridge.Value] else {
				return nil
			}

			return dictionary.reduce([:]) { (memo: Serializable, tuple: (key: String, value: Bridge.Value)) in
				var result = memo
				result[tuple.key] = bridge.serialize(tuple.value)
				return result
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			return object?.reduce([:]) { (memo: [String: Bridge.Value], tuple: (key: String, value: Bridge.Serializable)) in
				var result = memo
				result[tuple.key] = bridge.deserialize(tuple.value)
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
			guard let array = value as? [Bridge.Value] else {
				return nil
			}

			return array.map { bridge.serialize($0) } .compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			object?.map { bridge.deserialize($0) } .compact() as? Value
		}
	}
}
