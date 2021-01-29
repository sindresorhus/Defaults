import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Defaults.Bridge {
	public func migration(_ object: String?) -> Any? {
		nil
	}
}

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
Any `Value` which protocol conforms to Codable and Defaults.Serializable will use CodableBridge
to do the serialization and deserialization.
*/
extension Defaults {
	public struct TopLevelCodableBridge<Value: Codable>: CodableBridge {}
}

/**
RawRepresentableCodableBridge is indeed because if `enum SomeEnum: String, Codable, Defaults.Serializable`
the compiler will confuse between RawRepresentableBridge and TopLevelCodableBridge
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
			// We need to set `requiresSecureCoding` by ourself.
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

		public func migration(_ object: String?) -> Any? {
			Wrapped.bridge.migration(object)
		}
	}
}

extension Defaults {
	public struct ArrayBridge<Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [Element]
		public typealias Serializable = Any

		public func serialize(_ value: Value?) -> Serializable? {
			guard let array = value as? [Element.Value] else {
				return nil
			}

			return array.map { Element.bridge.serialize($0) }.compact()
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			// `object` should be an array of Element, when it is String, that means we need to do some migration.
			if object is String {
				guard let string = object as? Element.Serializable else {
					return nil
				}

				// pass jsonString to user-defined `deserialize`, in order to let the user do their own migration.
				return Element.bridge.deserialize(string) as? Value
			}

			guard let array = object as? [Element.Serializable] else {
				return nil
			}

			return array.map { Element.bridge.deserialize($0) }.compact() as? Value
		}

		public func migration(_ object: String?) -> Any? {
			Element.bridge.migration(object)
		}
	}
}

extension Defaults {
	public struct DictionaryBridge<Element: Defaults.Serializable>: Defaults.Bridge {
		public typealias Value = [String: Element.Value]
		public typealias Serializable = Any

		public func serialize(_ value: Value?) -> Serializable? {
			guard let dictionary = value else {
				return nil
			}

			return dictionary.reduce(into: [String: Element.Serializable]()) { memo, tuple in
				memo[tuple.key] = Element.bridge.serialize(tuple.value)
			}
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			// `object` should be a dictionary which `Key` is String and `Value` is Serializable,
			// When it is String, that means we need to do some migration.
			if object is String {
				guard let string = object as? Element.Serializable else {
					return nil
				}

				// pass jsonString to user-defined `deserialize`, in order to let the user do their own migration.
				return Element.bridge.deserialize(string) as? Value
			}

			guard let dictionary = object as? [String: Element.Serializable] else {
				return nil
			}

			return dictionary.reduce(into: Value()) { memo, tuple in
				memo[tuple.key] = Element.bridge.deserialize(tuple.value)
			}
		}

		public func migration(_ object: String?) -> Any? {
			Element.bridge.migration(object)
		}
	}
}

/**
We need both `SetBridge` and `SetAlgebraBridge`.

Because `Set` conforms to `Sequence` but `SetAlgebra` not.

Set conforms to `Sequence`, so we can convert it to an array with `Array.init<S>(S)` and store it in the `UserDefaults`.

But `SetAlgebra` does not, so it is hard to convert it to an array.

Thats why we need `Defaults.SetAlgebraSerializable` protocol to convert it to an array.
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
				// `object` should be an array of Element, when it is String, that means we need to do some migration
				if object is String {
					guard
						let object = object as? String,
						let data = object.data(using: .utf8),
						// `JSONSerialization.jsonObject` will always convert a string to a Foundation object
						let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Element]
					else {
						return nil
					}

					return Set(array)
				}

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

		public func migration(_ object: String?) -> Any? {
			if let set = Element.bridge.migration(object) as? Value {
				return set
			} else if let array = Element.bridge.migration(object) as? [Element] {
				return Set(array)
			}

			return nil
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
