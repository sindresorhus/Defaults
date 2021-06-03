import CoreGraphics
import Foundation

extension Defaults {
  /**
  Have an internal property `value` which` should always be a UserDefaults native supported type.

  `get` will deserialize internal value to  the type user explicit in function parameter.

  ```
  let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)
  print(Defaults[any].get(Int.self)) //=> 121_314
  ```

  `set`will serialize `Value` to UserDefaults native supported type and assign it to internal `value`.

  ```
  let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)
  Defaults[any].set("🦄")
  print(Defaults[any].get(String.self)) //=> 🦄
  ```

  - Note: the only way to assign non-serializable value is using `ExpressibleByArrayLiteral` or `ExpressibleByDictionaryLiteral` to assign a type which is not UserDefaults native supported type.

  ```
  private enum mime: String, Defaults.Serializable {
    case JSON = "application/json"
  }
  let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)

  // Failed: Attempt to insert non-property list object
  Defaults[any] = [mime.JSON]

  // Success
  Defaults[any].set(value: [mime.JSON])
  ```
  */
  public struct AnySerializable: Defaults.Serializable {
    var value: Any
    public static let bridge = AnyBridge()

    init<T>(value: T?) {
      self.value = value ?? ()
    }

    public init<Value: Defaults.Serializable>(_ value: Value) {
      self.value = Value.toSerializable(value) ?? ()
    }

    public func get<Value: Defaults.Serializable>(_: Value.Type) -> Value? {
      Value.toValue(self.value)
    }

    public mutating func set<Value: Defaults.Serializable>(value: Value) {
      self.value = Value.toSerializable(value) ?? ()
    }
  }
}

extension Defaults.AnySerializable: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch value {
    case let value as Data:
      return hasher.combine(value)
    case let value as Date:
      return hasher.combine(value)
    case let value as Bool:
      return hasher.combine(value)
    case let value as UInt8:
      return hasher.combine(value)
    case let value as Int8:
      return hasher.combine(value)
    case let value as UInt16:
      return hasher.combine(value)
    case let value as Int16:
      return hasher.combine(value)
    case let value as UInt32:
      return hasher.combine(value)
    case let value as Int32:
      return hasher.combine(value)
    case let value as UInt64:
      return hasher.combine(value)
    case let value as Int64:
      return hasher.combine(value)
    case let value as UInt:
      return hasher.combine(value)
    case let value as Int:
      return hasher.combine(value)
    case let value as Float:
      return hasher.combine(value)
    case let value as Double:
      return hasher.combine(value)
    case let value as CGFloat:
      return hasher.combine(value)
    case let value as String:
      return hasher.combine(value)
    case let value as [AnyHashable: AnyHashable]:
      return hasher.combine(value)
    case let value as [AnyHashable]:
      return hasher.combine(value)
    default:
      break
    }
  }
}

extension Defaults.AnySerializable: Equatable {
  public static func == (lhs: Defaults.AnySerializable, rhs: Defaults.AnySerializable) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (lhs as Data, rhs as Data):
      return lhs == rhs
    case let (lhs as Date, rhs as Date):
      return lhs == rhs
    case let (lhs as Bool, rhs as Bool):
      return lhs == rhs
    case let (lhs as UInt8, rhs as UInt8):
      return lhs == rhs
    case let (lhs as Int8, rhs as Int8):
      return lhs == rhs
    case let (lhs as UInt16, rhs as UInt16):
      return lhs == rhs
    case let (lhs as Int16, rhs as Int16):
      return lhs == rhs
    case let (lhs as UInt32, rhs as UInt32):
      return lhs == rhs
    case let (lhs as Int32, rhs as Int32):
      return lhs == rhs
    case let (lhs as UInt64, rhs as UInt64):
      return lhs == rhs
    case let (lhs as Int64, rhs as Int64):
      return lhs == rhs
    case let (lhs as UInt, rhs as UInt):
      return lhs == rhs
    case let (lhs as Int, rhs as Int):
      return lhs == rhs
    case let (lhs as Float, rhs as Float):
      return lhs == rhs
    case let (lhs as Double, rhs as Double):
      return lhs == rhs
    case let (lhs as CGFloat, rhs as CGFloat):
      return lhs == rhs
    case let (lhs as String, rhs as String):
      return lhs == rhs
    case let (lhs as [AnyHashable: Any], rhs as [AnyHashable: Any]):
      return lhs.toDictionary() == rhs.toDictionary()
    case let (lhs as [Any], rhs as [Any]):
      return lhs.toSequence() == rhs.toSequence()
    default:
      return false
    }
  }
}

extension Defaults.AnySerializable: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(value: value)
  }
}

extension Defaults.AnySerializable: ExpressibleByNilLiteral {
  public init(nilLiteral _: ()) {
    self.init(value: nil as Any?)
  }
}

extension Defaults.AnySerializable: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self.init(value: value)
  }
}

extension Defaults.AnySerializable: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(value: value)
  }
}

extension Defaults.AnySerializable: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self.init(value: value)
  }
}

extension Defaults.AnySerializable: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Any...) {
    self.init(value: elements)
  }
}

extension Defaults.AnySerializable: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
    self.init(value: [AnyHashable: Any](uniqueKeysWithValues: elements))
  }
}

extension Defaults.AnySerializable: _DefaultsOptionalType {
  public var isNil: Bool { value is Void }
}

extension Sequence {
  fileprivate func toSequence() -> [Defaults.AnySerializable] {
    map { Defaults.AnySerializable(value: $0) }
  }
}

extension Dictionary {
  fileprivate func toDictionary() -> [AnyHashable: Defaults.AnySerializable] {
    reduce(into: [AnyHashable: Defaults.AnySerializable]()) { memo, tuple in memo[tuple.key] = Defaults.AnySerializable(value: tuple.value) }
  }
}
