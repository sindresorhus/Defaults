import Defaults
import Foundation
import XCTest

private enum mime: String, Defaults.Serializable {
  case JSON = "application/json"
}

private struct CodableUnicorn: Defaults.Serializable, Codable {
  let is_missing: Bool
}

private struct Unicorn: Defaults.Serializable, Hashable {
  static let bridge = UnicornBridge()
  let is_missing: Bool
}

private struct UnicornBridge: Defaults.Bridge {
  typealias Value = Unicorn
  typealias Serializable = Bool

  func serialize(_ value: Value?) -> Serializable? {
    value?.is_missing
  }

  func deserialize(_ object: Serializable?) -> Value? {
    return Value(is_missing: object!)
  }
}

extension Defaults.Keys {
  fileprivate static let magic = Key<[String: Defaults.AnySerializable]>("magic", default: [:])
  fileprivate static let anyKey = Key<Defaults.AnySerializable>("anyKey", default: "🦄")
  fileprivate static let anyArrayKey = Key<[Defaults.AnySerializable]>("anyArrayKey", default: ["No.1 🦄", "No.2 🦄"])
  fileprivate static let anyDictionaryKey = Key<[String: Defaults.AnySerializable]>("anyDictionaryKey", default: ["unicorn": "🦄"])
}

final class DefaultsAnySerializableTests: XCTestCase {
  override func setUp() {
    super.setUp()
    Defaults.removeAll()
  }

  override func tearDown() {
    super.tearDown()
    Defaults.removeAll()
  }

  func testReadMeExample() {
    Defaults[.magic]["unicorn"] = "🦄"
    Defaults[.magic]["number"] = 3
    Defaults[.magic]["boolean"] = true
    Defaults[.magic]["enum"] = Defaults.AnySerializable(mime.JSON)
    XCTAssertEqual(Defaults[.magic]["unicorn"]?.get(String.self), "🦄")
    XCTAssertEqual(Defaults[.magic]["number"]?.get(Int.self) , 3)
    XCTAssertEqual(Defaults[.magic]["boolean"]?.get(Bool.self) , true)
    XCTAssertEqual(Defaults[.magic]["enum"]?.get(mime.self) , mime.JSON)
  }

  func testKey() {
    // Test Int
    let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)
    XCTAssertEqual(Defaults[any].get(Int.self) , 121_314)
    // Test Int8
    let int8 = Int8.max
    Defaults[any] = Defaults.AnySerializable(int8)
    XCTAssertEqual(Defaults[any].get(Int8.self), int8)
    // Test Int16
    let int16 = Int16.max
    Defaults[any] = Defaults.AnySerializable(int16)
    XCTAssertEqual(Defaults[any].get(Int16.self), int16)
    // Test Int32
    let int32 = Int32.max
    Defaults[any] = Defaults.AnySerializable(int32)
    XCTAssertEqual(Defaults[any].get(Int32.self), int32)
    // Test Int64
    let int64 = Int64.max
    Defaults[any] = Defaults.AnySerializable(int64)
    XCTAssertEqual(Defaults[any].get(Int64.self), int64)
    // Test UInt
    let uint = UInt.max
    Defaults[any] = Defaults.AnySerializable(uint)
    XCTAssertEqual(Defaults[any].get(UInt.self), uint)
    // Test UInt8
    let uint8 = UInt8.max
    Defaults[any] = Defaults.AnySerializable(uint8)
    XCTAssertEqual(Defaults[any].get(UInt8.self), uint8)
    // Test UInt16
    let uint16 = UInt16.max
    Defaults[any] = Defaults.AnySerializable(uint16)
    XCTAssertEqual(Defaults[any].get(UInt16.self), uint16)
    // Test UInt32
    let uint32 = UInt32.max
    Defaults[any] = Defaults.AnySerializable(uint32)
    XCTAssertEqual(Defaults[any].get(UInt32.self), uint32)
    // Test UInt64
    let uint64 = UInt64.max
    Defaults[any] = Defaults.AnySerializable(uint64)
    XCTAssertEqual(Defaults[any].get(UInt64.self), uint64)
    // Test Double
    Defaults[any] = 12_131.4
    XCTAssertEqual(Defaults[any].get(Double.self), 12_131.4)
    // Test Bool
    Defaults[any] = true
    XCTAssertTrue(Defaults[any].get(Bool.self)!)
    // Test String
    Defaults[any] = "121314"
    XCTAssertEqual(Defaults[any].get(String.self), "121314")
    // Test Float
    let float: Float = 12_131.4
    Defaults[any] = Defaults.AnySerializable(float)
    XCTAssertEqual(Defaults[any].get(Float.self), float)
    // Test Date
    let date = Date()
    Defaults[any] = Defaults.AnySerializable(date)
    XCTAssertEqual(Defaults[any].get(Date.self), date)
    // Test Data
    let data = "121314".data(using: .utf8)
    Defaults[any] = Defaults.AnySerializable(data)
    XCTAssertEqual(Defaults[any].get(Data.self), data)
    // Test Array
    Defaults[any] = [1, 2, 3]
    if let array = Defaults[any].get([Int].self) {
      XCTAssertEqual(array[0], 1)
      XCTAssertEqual(array[1], 2)
      XCTAssertEqual(array[2], 3)
    }
    // Test Dictionary
    Defaults[any] = ["unicorn": "🦄", "boolean": true, "number": 3]
    if let dictionary = Defaults[any].get([String: Defaults.AnySerializable].self) {
      XCTAssertEqual(dictionary["unicorn"]?.get(String.self), "🦄")
      XCTAssertTrue(dictionary["boolean"]!.get(Bool.self)!)
      XCTAssertEqual(dictionary["number"]?.get(Int.self), 3)
    }
    // Test Set
    Defaults[any].set(value: Set([1]))
    XCTAssertEqual(Defaults[any].get(Set<Int>.self)?.first, 1)
    // Test URL
    Defaults[any].set(value: URL(string: "https://example.com")!)
    XCTAssertEqual(Defaults[any].get(URL.self)!, URL(string: "https://example.com")!)
    #if os(macOS)
    // Test NSColor
    Defaults[any].set(value: NSColor(red: CGFloat(103) / CGFloat(0xFF), green: CGFloat(132) / CGFloat(0xFF), blue: CGFloat(255) / CGFloat(0xFF), alpha: 0.987))
    XCTAssertEqual(Defaults[any].get(NSColor.self)!.alphaComponent, 0.987)
    #else
    // Test UIColor
    Defaults[any] = Defaults.AnySerializable(UIColor(red: CGFloat(103) / CGFloat(0xFF), green: CGFloat(132) / CGFloat(0xFF), blue: CGFloat(255) / CGFloat(0xFF), alpha: 0.654))
    XCTAssertEqual( Defaults[any].get(UIColor.self)?.cgColor.alpha, 0.654)
    #endif
    // Test Codable type
    Defaults[any].set(value: CodableUnicorn(is_missing: false))
    XCTAssertFalse(Defaults[any].get(CodableUnicorn.self)!.is_missing)
    // Test Custom type
    Defaults[any].set(value: Unicorn(is_missing: true))
    XCTAssertTrue(Defaults[any].get(Unicorn.self)!.is_missing)
    // Test nil
    Defaults[any] = nil
    XCTAssertEqual(Defaults[any], 121_314)
  }

  func testOptionalKey() {
    let key = Defaults.Key<Defaults.AnySerializable?>("independentOptionalAnyKey")
    XCTAssertNil(Defaults[key])
    Defaults[key] = 12_131.4
    XCTAssertEqual(Defaults[key]!.get(Double.self), 12_131.4)
    Defaults[key] = nil
    XCTAssertNil(Defaults[key])
  }

  func testArrayKey() {
    let key = Defaults.Key<[Defaults.AnySerializable]>("independentArrayAnyKey", default: [123, 456])
    XCTAssertEqual(Defaults[key][0].get(Int.self), 123)
    XCTAssertEqual(Defaults[key][1].get(Int.self), 456)
    Defaults[key][0] = 12_131.4
    XCTAssertEqual(Defaults[key][0].get(Double.self), 12_131.4)
  }

  func testSetKey() {
    let key = Defaults.Key<Set<Defaults.AnySerializable>>("independentArrayAnyKey", default: [123])
    XCTAssertEqual(Defaults[key].first?.get(Int.self), 123)
    Defaults[key].insert(12_131.4)
    XCTAssertTrue(Defaults[key].contains(12_131.4))
    let date = Defaults.AnySerializable(Date())
    Defaults[key].insert(date)
    XCTAssertTrue(Defaults[key].contains(date))
    let data = Defaults.AnySerializable("Hello World!".data(using: .utf8))
    Defaults[key].insert(data)
    XCTAssertTrue(Defaults[key].contains(data))
    let int = Defaults.AnySerializable(Int.max)
    Defaults[key].insert(int)
    XCTAssertTrue(Defaults[key].contains(int))
    let int8 = Defaults.AnySerializable(Int8.max)
    Defaults[key].insert(int8)
    XCTAssertTrue(Defaults[key].contains(int8))
    let int16 = Defaults.AnySerializable(Int16.max)
    Defaults[key].insert(int16)
    XCTAssertTrue(Defaults[key].contains(int16))
    let int32 = Defaults.AnySerializable(Int32.max)
    Defaults[key].insert(int32)
    XCTAssertTrue(Defaults[key].contains(int32))
    let int64 = Defaults.AnySerializable(Int64.max)
    Defaults[key].insert(int64)
    XCTAssertTrue(Defaults[key].contains(int64))
    let uint = Defaults.AnySerializable(UInt.max)
    Defaults[key].insert(uint)
    XCTAssertTrue(Defaults[key].contains(uint))
    let uint8 = Defaults.AnySerializable(UInt8.max)
    Defaults[key].insert(uint8)
    XCTAssertTrue(Defaults[key].contains(uint8))
    let uint16 = Defaults.AnySerializable(UInt16.max)
    Defaults[key].insert(uint16)
    XCTAssertTrue(Defaults[key].contains(uint16))
    let uint32 = Defaults.AnySerializable(UInt32.max)
    Defaults[key].insert(uint32)
    XCTAssertTrue(Defaults[key].contains(uint32))
    let uint64 = Defaults.AnySerializable(UInt64.max)
    Defaults[key].insert(uint64)
    XCTAssertTrue(Defaults[key].contains(uint64))

    let bool: Defaults.AnySerializable = false
    Defaults[key].insert(bool)
    XCTAssertTrue(Defaults[key].contains(bool))

    let float = Defaults.AnySerializable(Float(1_213.14))
    Defaults[key].insert(float)
    XCTAssertTrue(Defaults[key].contains(float))

    let cgFloat = Defaults.AnySerializable(CGFloat(12_131.415))
    Defaults[key].insert(cgFloat)
    XCTAssertTrue(Defaults[key].contains(cgFloat))

    let string = Defaults.AnySerializable("Hello World!")
    Defaults[key].insert(string)
    XCTAssertTrue(Defaults[key].contains(string))

    let array: Defaults.AnySerializable = [1, 2, 3, 4]
    Defaults[key].insert(array)
    XCTAssertTrue(Defaults[key].contains(array))

    let dictionary: Defaults.AnySerializable = ["Hello": "World!"]
    Defaults[key].insert(dictionary)
    XCTAssertTrue(Defaults[key].contains(dictionary))

    let unicorn = Defaults.AnySerializable(Unicorn(is_missing: true))
    Defaults[key].insert(unicorn)
    XCTAssertTrue(Defaults[key].contains(unicorn))
  }

  func testArrayOptionalKey() {
    let key = Defaults.Key<[Defaults.AnySerializable]?>("testArrayOptionalAnyKey")
    XCTAssertNil(Defaults[key])
    Defaults[key] = [123]
    Defaults[key]?.append(456)
    XCTAssertEqual(Defaults[key]![0].get(Int.self), 123)
    XCTAssertEqual(Defaults[key]![1].get(Int.self), 456)
    Defaults[key]![0] = 12_131.4
    XCTAssertEqual(Defaults[key]![0].get(Double.self), 12_131.4)
  }

  func testNestedArrayKey() {
    let key = Defaults.Key<[[Defaults.AnySerializable]]>("testNestedArrayAnyKey", default: [[123]])
    Defaults[key][0].append(456)
    XCTAssertEqual(Defaults[key][0][0].get(Int.self), 123)
    XCTAssertEqual(Defaults[key][0][1].get(Int.self), 456)
    Defaults[key].append([12_131.4])
    XCTAssertEqual(Defaults[key][1][0].get(Double.self), 12_131.4)
  }

  func testDictionaryKey() {
    let key = Defaults.Key<[String: Defaults.AnySerializable]>("independentDictionaryAnyKey", default: ["unicorn": ""])
    XCTAssertEqual(Defaults[key]["unicorn"]?.get(String.self), "")
    Defaults[key]["unicorn"] = "🦄"
    XCTAssertEqual(Defaults[key]["unicorn"]?.get(String.self), "🦄")
    Defaults[key]["number"] = 3
    Defaults[key]["boolean"] = true
    XCTAssertEqual(Defaults[key]["number"]?.get(Int.self), 3)
    XCTAssertEqual(Defaults[key]["boolean"]?.get(Bool.self), true)
    Defaults[key]["set"] = Defaults.AnySerializable(Set([1]))
    XCTAssertEqual(Defaults[key]["set"]!.get(Set<Int>.self)!.first, 1)
    Defaults[key]["nil"] = nil
    XCTAssertNil(Defaults[key]["nil"])
  }

  func testDictionaryOptionalKey() {
    let key = Defaults.Key<[String: Defaults.AnySerializable]?>("independentDictionaryOptionalAnyKey")
    XCTAssertNil(Defaults[key])
    Defaults[key] = ["unicorn": "🦄"]
    XCTAssertEqual(Defaults[key]?["unicorn"]?.get(String.self), "🦄")
    Defaults[key]?["number"] = 3
    Defaults[key]?["boolean"] = true
    XCTAssertEqual(Defaults[key]?["number"]?.get(Int.self), 3)
    XCTAssertEqual(Defaults[key]?["boolean"]?.get(Bool.self), true)
  }

  func testDictionaryArrayKey() {
    let key = Defaults.Key<[String: [Defaults.AnySerializable]]>("independentDictionaryArrayAnyKey", default: ["number": [1]])
    XCTAssertEqual(Defaults[key]["number"]?[0].get(Int.self), 1)
    Defaults[key]["number"]?.append(2)
    Defaults[key]["unicorn"] = ["No.1 🦄"]
    Defaults[key]["unicorn"]?.append("No.2 🦄")
    Defaults[key]["unicorn"]?.append("No.3 🦄")
    Defaults[key]["boolean"] = [true]
    Defaults[key]["boolean"]?.append(false)
    XCTAssertEqual(Defaults[key]["number"]?[1].get(Int.self), 2)
    XCTAssertEqual(Defaults[key]["unicorn"]?[0].get(String.self), "No.1 🦄")
    XCTAssertEqual(Defaults[key]["unicorn"]?[1].get(String.self), "No.2 🦄")
    XCTAssertEqual(Defaults[key]["unicorn"]?[2].get(String.self), "No.3 🦄")
    XCTAssertTrue(Defaults[key]["boolean"]![0].get(Bool.self)!)
    XCTAssertFalse(Defaults[key]["boolean"]![1].get(Bool.self)!)
  }

  func testType() {
    XCTAssertEqual(Defaults[.anyKey].get(String.self), "🦄")
    Defaults[.anyKey] = 123
    XCTAssertEqual(Defaults[.anyKey].get(Int.self), 123)
  }

  func testArrayType() {
    XCTAssertEqual(Defaults[.anyArrayKey][0].get(String.self), "No.1 🦄")
    XCTAssertEqual(Defaults[.anyArrayKey][1].get(String.self), "No.2 🦄")
    Defaults[.anyArrayKey].append(123)
    XCTAssertEqual(Defaults[.anyArrayKey][2].get(Int.self), 123)
  }

  func testDictionaryType() {
    XCTAssertEqual(Defaults[.anyDictionaryKey]["unicorn"]?.get(String.self), "🦄")
    Defaults[.anyDictionaryKey]["number"] = 3
    XCTAssertEqual(Defaults[.anyDictionaryKey]["number"]?.get(Int.self), 3)
    Defaults[.anyDictionaryKey]["boolean"] = true
    XCTAssertTrue(Defaults[.anyDictionaryKey]["boolean"]!.get(Bool.self)!)
    Defaults[.anyDictionaryKey]["array"] = [1, 2]
    if let array = Defaults[.anyDictionaryKey]["array"]?.get([Int].self) {
      XCTAssertEqual(array[0], 1)
      XCTAssertEqual(array[1], 2)
    }
  }

  @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
  func testObserveKeyCombine() {
    let key = Defaults.Key<Defaults.AnySerializable>("observeAnyKeyCombine", default: 123)
    let expect = expectation(description: "Observation closure being called")

    let publisher = Defaults
      .publisher(key, options: [])
      .map { ($0.oldValue, $0.newValue) }
      .collect(2)

    let expectedValue: [(Defaults.AnySerializable, Defaults.AnySerializable)] = [(123, "🦄"), ("🦄", 123)]

    let cancellable = publisher.sink { tuples in
      for (index, expected) in expectedValue.enumerated() {
        if (tuples[index].0.get(Int.self) != nil) {
          XCTAssertEqual(expected.0.get(Int.self), tuples[index].0.get(Int.self))
          XCTAssertEqual(expected.1.get(String.self), tuples[index].1.get(String.self))
        } else {
          XCTAssertEqual(expected.0.get(String.self), tuples[index].0.get(String.self))
          XCTAssertEqual(expected.1.get(Int.self), tuples[index].1.get(Int.self))
        }
      }

      expect.fulfill()
    }

    Defaults[key] = "🦄"
    Defaults.reset(key)
    cancellable.cancel()

    waitForExpectations(timeout: 10)
  }

  @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
  func testObserveOptionalKeyCombine() {
    let key = Defaults.Key<Defaults.AnySerializable?>("observeAnyOptionalKeyCombine")
    let expect = expectation(description: "Observation closure being called")

    let publisher = Defaults
      .publisher(key, options: [])
      .map { ($0.oldValue, $0.newValue) }
      .collect(3)

    let expectedValue: [(Defaults.AnySerializable?, Defaults.AnySerializable?)] = [(nil, 123), (123, "🦄"), ("🦄", nil)]

    let cancellable = publisher.sink { tuples in
      for (index, expected) in expectedValue.enumerated() {
        if (tuples[index].0?.get(Int.self) != nil) {
          XCTAssertEqual(expected.0?.get(Int.self), tuples[index].0?.get(Int.self))
          XCTAssertEqual(expected.1?.get(String.self), tuples[index].1?.get(String.self))
        } else if (tuples[index].0?.get(String.self) != nil) {
          XCTAssertEqual(tuples[index].0?.get(String.self), tuples[index].0?.get(String.self))
          XCTAssertNil(tuples[index].1)
        } else {
          XCTAssertNil(tuples[index].0)
          XCTAssertEqual(expected.1?.get(Int.self), tuples[index].1?.get(Int.self))
        }
      }

      expect.fulfill()
    }

    Defaults[key] = 123
    Defaults[key] = "🦄"
    Defaults.reset(key)
    cancellable.cancel()

    waitForExpectations(timeout: 10)
  }

  func testObserveKey() {
    let key = Defaults.Key<Defaults.AnySerializable>("observeAnyKey", default: 123)
    let expect = expectation(description: "Observation closure being called")

    var observation: Defaults.Observation!
    observation = Defaults.observe(key, options: []) { change in
      XCTAssertEqual(change.oldValue.get(Int.self), 123)
      XCTAssertEqual(change.newValue.get(String.self), "🦄")
      observation.invalidate()
      expect.fulfill()
    }

    Defaults[key] = "🦄"
    observation.invalidate()

    waitForExpectations(timeout: 10)
  }

  func testObserveOptionalKey() {
    let key = Defaults.Key<Defaults.AnySerializable?>("observeAnyOptionalKey")
    let expect = expectation(description: "Observation closure being called")

    var observation: Defaults.Observation!
    observation = Defaults.observe(key, options: []) { change in
      XCTAssertNil(change.oldValue)
      XCTAssertEqual(change.newValue?.get(String.self), "🦄")
      observation.invalidate()
      expect.fulfill()
    }

    Defaults[key] = "🦄"
    observation.invalidate()

    waitForExpectations(timeout: 10)
  }
}
