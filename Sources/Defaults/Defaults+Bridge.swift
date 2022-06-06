import Foundation
import SwiftUI
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
	public struct TopLevelCodableBridge<Value: Codable>: CodableBridge {
		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}
	}
}

/**
`RawRepresentableCodableBridge` is needed because, for example, with `enum SomeEnum: String, Codable, Defaults.Serializable`, the compiler will be confused between `RawRepresentableBridge` and `TopLevelCodableBridge`.
*/
extension Defaults {
	public struct RawRepresentableCodableBridge<Value: RawRepresentable & Codable>: CodableBridge {
		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}
	}
}

/**
This exists to avoid compiler ambiguity.
*/
extension Defaults {
	public struct CodableNSSecureCodingBridge<Value: Codable & NSSecureCoding>: CodableBridge {
		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}
	}
}

extension Defaults {
	public struct URLBridge: CodableBridge {
		public typealias Value = URL
	}
}

extension Defaults {
	public struct RawRepresentableBridge<Value: RawRepresentable>: Bridge {
		public typealias Value = Value
		public typealias Serializable = Value.RawValue

		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}

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
	public struct NSSecureCodingBridge<Value: NSSecureCoding>: Bridge {
		public typealias Value = Value
		public typealias Serializable = Data

		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}

		public func serialize(_ value: Value?) -> Serializable? {
			guard let object = value else {
				return nil
			}

			return try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
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
	public struct OptionalBridge<Wrapped: Serializable>: Bridge {
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
	public struct ArrayBridge<Element: Serializable>: Bridge {
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
	public struct DictionaryBridge<Key: LosslessStringConvertible & Hashable, Element: Serializable>: Bridge {
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
	public struct SetBridge<Element: Serializable & Hashable>: Bridge {
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
	public struct SetAlgebraBridge<Value: SetAlgebraSerializable>: Bridge where Value.Element: Serializable {
		public typealias Value = Value
		public typealias Element = Value.Element
		public typealias Serializable = Any

		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}

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
	public struct CollectionBridge<Value: CollectionSerializable>: Bridge where Value.Element: Serializable {
		public typealias Value = Value
		public typealias Element = Value.Element
		public typealias Serializable = Any

		// TODO: A temporary workaround for Xcode 13.3 compiler issue. Should remove after https://bugs.swift.org/browse/SR-15807 is fixed.
		public init() {}

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
	public struct UUIDBridge: Bridge {
		public typealias Value = UUID
		public typealias Serializable = String

		public func serialize(_ value: Value?) -> Serializable? {
			value?.uuidString
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let object = object else {
				return nil
			}

			return .init(uuidString: object)
		}
	}
}

extension Defaults {
	public struct RangeBridge<T: RangeSerializable>: Bridge {
		public typealias Value = T
		public typealias Serializable = [Any]
		typealias Bound = T.Bound

		public func serialize(_ value: Value?) -> Serializable? {
			guard let value = value else {
				return nil
			}

			if Bound.isNativelySupportedType {
				return [value.lowerBound, value.upperBound]
			}

			guard
				let lowerBound = Bound.bridge.serialize(value.lowerBound as? Bound.Value),
				let upperBound = Bound.bridge.serialize(value.upperBound as? Bound.Value)
			else {
				return nil
			}

			return [lowerBound, upperBound]
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			guard let object = object else {
				return nil
			}

			if Bound.isNativelySupportedType {
				guard
					let lowerBound = object[safe: 0] as? Bound,
					let upperBound = object[safe: 1] as? Bound
				else {
					return nil
				}

				return .init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
			}

			guard
				let lowerBound = Bound.bridge.deserialize(object[safe: 0] as? Bound.Serializable) as? Bound,
				let upperBound = Bound.bridge.deserialize(object[safe: 1] as? Bound.Serializable) as? Bound
			else {
				return nil
			}

			return .init(uncheckedBounds: (lower: lowerBound, upper: upperBound))
		}
	}
}

extension Defaults {
	/**
	The bridge which is responsible for `SwiftUI.Color` serialization and deserialization.

	It is unsafe to convert `SwiftUI.Color` to `UIColor` and use `UIColor.bridge` to serialize it.
	Because `UIColor` does not hold a color space, but `Swift.Color` does(which means color space might get lost in the conversion).
	The bridge will always trying to preserve color space whenever `Color.cgColor` exists.
	Only if `Color.cgColor` is `nil`, it will use `UIColor.bridge` to do serialization and deserialization.
	*/
	@available(iOS 15.0, macOS 11.0, tvOS 15.0, watchOS 8.0, iOSApplicationExtension 15.0, macOSApplicationExtension 11.0, tvOSApplicationExtension 15.0, watchOSApplicationExtension 8.0, *)
	public struct ColorBridge: Bridge {
		public typealias Value = Color
		public typealias Serializable = Any

		#if os(macOS)
		private typealias NativeColor = NSColor
		#else
		private typealias NativeColor = UIColor
		#endif

		public func serialize(_ value: Value?) -> Serializable? {
			guard let value = value else {
				return nil
			}

			guard
				let cgColor = value.cgColor,
				let colorSpace = cgColor.colorSpace?.name as? String,
				let components = cgColor.components
			else {
				return NativeColor.bridge.serialize(NativeColor(value))
			}

			return [colorSpace, components]
		}

		public func deserialize(_ object: Serializable?) -> Value? {
			if let object = object as? NativeColor.Serializable {
				guard let nativeColor = NativeColor.bridge.deserialize(object) else {
					return nil
				}

				return Value(nativeColor)
			}

			guard
				let object = object as? [Any],
				let rawColorspace = object[0] as? String,
				let colorspace = CGColorSpace(name: rawColorspace as CFString),
				let components = object[1] as? [CGFloat],
				let cgColor = CGColor(colorSpace: colorspace, components: components)
			else {
				return nil
			}

			#if os(macOS)
			guard let nativeColor = NativeColor(cgColor: cgColor) else {
				return nil
			}
			#else
			let nativeColor = NativeColor(cgColor: cgColor)
			#endif

			return Value(nativeColor)
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
