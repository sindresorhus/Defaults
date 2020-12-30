import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Defaults.CodableBridge {
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

	public struct NSSecureCodingBridge<Value: NSSecureCoding>: Defaults.Bridge {
		public func serialize(_ value: Value?) -> Data? {
			guard let object = value else {
				return nil
			}

			// Version below macOS 10.13 and iOS 11.0 does not support `archivedData(withRootObject:requiringSecureCoding:)`.
			// We need to set `requiresSecureCoding` by ourself.
			if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *) {
				return try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
			} else {
				let keyedArchiver = NSKeyedArchiver()
				keyedArchiver.requiresSecureCoding = true
				keyedArchiver.encode(object, forKey: NSKeyedArchiveRootObjectKey)
				return keyedArchiver.encodedData
			};
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

	public struct OptionalBridge<Wrapped: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = Wrapped.Value
		public typealias Serializable = Wrapped.Serializable

		public func serialize(_ value: Value?) -> Serializable? {
			Wrapped.bridge.serialize(value)
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			Wrapped.bridge.deserialize(object)
		}
	}

	public struct DictionaryBridge<Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [String: Element]
		public typealias Serializable = [String: Element.Serializable]
		
		public func serialize(_ value: Value?) -> Serializable? {
			guard let dictionary = value as? [String: Element.Value] else {
				return nil
			}

			return dictionary.reduce([:]) { (memo: Serializable, tuple: (key: String, value: Element.Value)) in
				var result = memo
				result[tuple.key] = Element.bridge.serialize(tuple.value)
				return result
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			return object?.reduce([:]) { (memo: [String: Element.Value], tuple: (key: String, value: Element.Serializable)) in
				var result = memo
				result[tuple.key] = Element.bridge.deserialize(tuple.value)
				return result
			} as? Value
		}
	}

	public struct SetNativeBridge<Element: Defaults.NativelySupportedType & Hashable>: Defaults.Bridge {
		public func serialize(_ value: Set<Element>?) -> [Element]? {
			guard let value = value else {
				return nil
			}

			return Array(value)
		}

		public func deserialize(_ object: [Element]?) -> Set<Element>? {
			guard let object = object else {
				return nil
			}

			return Set(object)
		}
	}

	public struct SetBridge<Element: Defaults.Serializable & Hashable>: Defaults.Bridge {
		public typealias Value = Set<Element>
		public typealias Serializable = [Element.Bridge.Serializable]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let set = value else {
				return nil
			}

			return set.map { Element.bridge.serialize($0 as? Element.Value) } .compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let array = object?.map({ Element.bridge.deserialize($0) }) .compact() as? [Element] else {
				return nil
			}

			return Set(array)
		}
	}

	public struct ArrayBridge<Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [Element]
		public typealias Serializable = [Element.Serializable]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let array = value as? [Element.Value] else {
				return nil
			}
			let object = array.map { Element.bridge.serialize($0) } .compact()
			return object
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			return object?.map { Element.bridge.deserialize($0) } .compact() as? Value
		}
	}
}
