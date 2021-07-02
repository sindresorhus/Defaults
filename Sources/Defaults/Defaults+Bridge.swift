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
		guard let jsonString = object else {
			return nil
		}

		return [Value].init(jsonString: "[\(jsonString)]")?.first
	}
}

/**
Any `Value` that conforms to `Codable` and `Defaults.Serializable` will use `CodableBridge` to do the serialization and deserialization.
*/
extension Defaults {
	public struct TopLevelCodableBridge<Value: Codable>: CodableBridge {}
}

/**
`RawRepresentableCodableBridge` is needed because, for example, with `enum SomeEnum: String, Codable, Defaults.Serializable`, the compiler will be confused between `RawRepresentableBridge` and `TopLevelCodableBridge`.
*/
extension Defaults {
	public struct RawRepresentableCodableBridge<Value: RawRepresentable & Codable>: CodableBridge {}
}

extension Defaults {
	public struct URLBridge: CodableBridge {
		public typealias Value = URL
	}
}

extension Defaults {
	public struct RawRepresentableBridge<Value: RawRepresentable>: Defaults.Bridge {
		public typealias Value = Value
		public typealias Serializable = Value.RawValue

		public func serialize(_ value: Value?) -> Serializable? {
			value?.rawValue
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let rawValue = object else {
				return nil
			}

			return Value(rawValue: rawValue)
		}
	}
}

extension Defaults {
	public struct NSSecureCodingBridge<Value: NSSecureCoding>: Defaults.Bridge {
		public typealias Value = Value
		public typealias Serializable = Data

		public func serialize(_ value: Value?) -> Serializable? {
			guard let object = value else {
				return nil
			}

			// Version below macOS 10.13 and iOS 11.0 does not support `archivedData(withRootObject:requiringSecureCoding:)`.
			// We need to set `requiresSecureCoding` ourselves.
			if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, iOSApplicationExtension 11.0, macOSApplicationExtension 10.13, tvOSApplicationExtension 11.0, watchOSApplicationExtension 4.0, *) {
				return try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
			} else {
				let keyedArchiver = NSKeyedArchiver()
				keyedArchiver.requiresSecureCoding = true
				keyedArchiver.encode(object, forKey: NSKeyedArchiveRootObjectKey)
				return keyedArchiver.encodedData
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {
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
}

extension Defaults {
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
}

extension Defaults {
	public struct ArrayBridge<Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [Element]
		public typealias Serializable = [Element.Serializable]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let array = value as? [Element.Value] else {
				return nil
			}

			return array.map { Element.bridge.serialize($0) }.compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let array = object else {
				return nil
			}

			return array.map { Element.bridge.deserialize($0) }.compact() as? Value
		}
	}
}

extension Defaults {
	public struct DictionaryBridge<Key: LosslessStringConvertible & Hashable, Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [Key: Element.Value]
		public typealias Serializable = [String: Element.Serializable]

		public func serialize(_ value: Value?) -> Serializable? {
			guard let dictionary = value else {
				return nil
			}

			// `Key` which stored in `UserDefaults` have to be `String`
			return dictionary.reduce(into: Serializable()) { memo, tuple in
				memo[String(tuple.key)] = Element.bridge.serialize(tuple.value)
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let dictionary = object else {
				return nil
			}

			return dictionary.reduce(into: Value()) { memo, tuple in
				// Use `LosslessStringConvertible` to create `Key` instance
				guard let key = Key(tuple.key) else {
					return
				}

				memo[key] = Element.bridge.deserialize(tuple.value)
			}
		}
	}
}

/**
We need both `SetBridge` and `SetAlgebraBridge` because `Set` conforms to `Sequence` but `SetAlgebra` does not. `Set` conforms to `Sequence`, so we can convert it into an array with `Array.init<S>(S)` and store it in the `UserDefaults`. But `SetAlgebra` does not, so it is hard to convert it into an array. Thats why we need the `Defaults.SetAlgebraSerializable` protocol to convert it into an array.
*/
extension Defaults {
	public struct SetBridge<Element: Defaults.Serializable & Hashable>: Defaults.Bridge {
		public typealias Value = Set<Element>
		public typealias Serializable = Any

		public func serialize(_ value: Value?) -> Serializable? {
			guard let set = value else {
				return nil
			}

			if Element.isNativelySupportedType {
				return Array(set)
			}

			return set.map { Element.bridge.serialize($0 as? Element.Value) }.compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			if Element.isNativelySupportedType {
				guard let array = object as? [Element] else {
					return nil
				}

				return Set(array)
			}

			guard
				let array = object as? [Element.Serializable],
				let elements = array.map({ Element.bridge.deserialize($0) }).compact() as? [Element]
			else {
				return nil
			}

			return Set(elements)
		}
	}
}

extension Defaults {
	public struct SetAlgebraBridge<Value: Defaults.SetAlgebraSerializable>: Defaults.Bridge where Value.Element: Defaults.Serializable {
		public typealias Value = Value
		public typealias Element = Value.Element
		public typealias Serializable = Any

		public func serialize(_ value: Value?) -> Serializable? {
			guard let setAlgebra = value else {
				return nil
			}

			if Element.isNativelySupportedType {
				return setAlgebra.toArray()
			}

			return setAlgebra.toArray().map { Element.bridge.serialize($0 as? Element.Value) }.compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			if Element.isNativelySupportedType {
				guard let array = object as? [Element] else {
					return nil
				}

				return Value(array)
			}

			guard
				let array = object as? [Element.Serializable],
				let elements = array.map({ Element.bridge.deserialize($0) }).compact() as? [Element]
			else {
				return nil
			}

			return Value(elements)
		}
	}
}

extension Defaults {
	public struct CollectionBridge<Value: Defaults.CollectionSerializable>: Defaults.Bridge where Value.Element: Defaults.Serializable {
		public typealias Value = Value
		public typealias Element = Value.Element
		public typealias Serializable = Any

		public func serialize(_ value: Value?) -> Serializable? {
			guard let collection = value else {
				return nil
			}

			if Element.isNativelySupportedType {
				return Array(collection)
			}

			return collection.map { Element.bridge.serialize($0 as? Element.Value) }.compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			if Element.isNativelySupportedType {
				guard let array = object as? [Element] else {
					return nil
				}

				return Value(array)
			}

			guard
				let array = object as? [Element.Serializable],
				let elements = array.map({ Element.bridge.deserialize($0) }).compact() as? [Element]
			else {
				return nil
			}

			return Value(elements)
		}
	}
}

extension Defaults {
	public struct AnyBridge: Defaults.Bridge {
		public typealias Value = Defaults.AnySerializable
		public typealias Serializable = Any

		public func deserialize(_ object: Serializable?) -> Value? {
			Value(value: object)
    }

		public func serialize(_ value: Value?) -> Serializable? {
			value?.value
		}
	}
}
