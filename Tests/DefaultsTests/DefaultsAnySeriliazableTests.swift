import Defaults
import Foundation
import XCTest

private enum mime: String, Defaults.Serializable {
	case JSON = "application/json"
	case STREAM = "application/octet-stream"
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
		Value(is_missing: object!)
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
		let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: Defaults.AnySerializable(mime.JSON))
		if let mimeType: mime = Defaults[any].get() {
			XCTAssertEqual(mimeType, mime.JSON)
		}
		Defaults[any].set(mime.STREAM)
		if let mimeType: mime = Defaults[any].get() {
			XCTAssertEqual(mimeType, mime.STREAM)
		}
		Defaults[any].set(mime.JSON)
		if let mimeType: mime = Defaults[any].get() {
			XCTAssertEqual(mimeType, mime.JSON)
		}
		Defaults[.magic]["unicorn"] = "🦄"
		Defaults[.magic]["number"] = 3
		Defaults[.magic]["boolean"] = true
		Defaults[.magic]["enum"] = Defaults.AnySerializable(mime.JSON)
		XCTAssertEqual(Defaults[.magic]["unicorn"], "🦄")
		XCTAssertEqual(Defaults[.magic]["number"], 3)
		if let bool: Bool = Defaults[.magic]["unicorn"]?.get() {
			XCTAssertTrue(bool)
		}
		XCTAssertEqual(Defaults[.magic]["enum"]?.get(), mime.JSON)
		Defaults[.magic]["enum"]?.set(mime.STREAM)
		if let value: String = Defaults[.magic]["unicorn"]?.get() {
			XCTAssertEqual(value, "🦄")
		}
		if let mimeType: mime = Defaults[.magic]["enum"]?.get() {
			XCTAssertEqual(mimeType, mime.STREAM)
		}
		Defaults[any].set(mime.JSON)
		if let mimeType: mime = Defaults[any].get() {
			XCTAssertEqual(mime.JSON, mimeType)
		}
		Defaults[any].set(mime.STREAM)
		if let mimeType: mime = Defaults[any].get() {
			XCTAssertEqual(mime.STREAM, mimeType)
		}
	}

	func testKey() {
		// Test Int
		let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314)
		XCTAssertEqual(Defaults[any], 121_314)
		// Test Int8
		let int8 = Int8.max
		Defaults[any].set(int8)
		XCTAssertEqual(Defaults[any].get(), int8)
		// Test Int16
		let int16 = Int16.max
		Defaults[any].set(int16)
		XCTAssertEqual(Defaults[any].get(), int16)
		// Test Int32
		let int32 = Int32.max
		Defaults[any].set(int32)
		XCTAssertEqual(Defaults[any].get(), int32)
		// Test Int64
		let int64 = Int64.max
		Defaults[any].set(int64)
		XCTAssertEqual(Defaults[any].get(), int64)
		// Test UInt
		let uint = UInt.max
		Defaults[any].set(uint)
		XCTAssertEqual(Defaults[any].get(), uint)
		// Test UInt8
		let uint8 = UInt8.max
		Defaults[any].set(uint8)
		XCTAssertEqual(Defaults[any].get(), uint8)
		// Test UInt16
		let uint16 = UInt16.max
		Defaults[any].set(uint16)
		XCTAssertEqual(Defaults[any].get(), uint16)
		// Test UInt32
		let uint32 = UInt32.max
		Defaults[any].set(uint32)
		XCTAssertEqual(Defaults[any].get(), uint32)
		// Test UInt64
		let uint64 = UInt64.max
		Defaults[any].set(uint64)
		XCTAssertEqual(Defaults[any].get(), uint64)
		// Test Double
		Defaults[any] = 12_131.4
		XCTAssertEqual(Defaults[any], 12_131.4)
		// Test Bool
		Defaults[any] = true
		XCTAssertTrue(Defaults[any].get(Bool.self)!)
		// Test String
		Defaults[any] = "121314"
		XCTAssertEqual(Defaults[any], "121314")
		// Test Float
		Defaults[any].set(12_131.456, type: Float.self)
		XCTAssertEqual(Defaults[any].get(Float.self), 12_131.456)
		// Test Date
		let date = Date()
		Defaults[any].set(date)
		XCTAssertEqual(Defaults[any].get(Date.self), date)
		// Test Data
		let data = "121314".data(using: .utf8)
		Defaults[any].set(data)
		XCTAssertEqual(Defaults[any].get(Data.self), data)
		// Test Array
		Defaults[any] = [1, 2, 3]
		if let array: [Int] = Defaults[any].get() {
			XCTAssertEqual(array[0], 1)
			XCTAssertEqual(array[1], 2)
			XCTAssertEqual(array[2], 3)
		}
		// Test Dictionary
		Defaults[any] = ["unicorn": "🦄", "boolean": true, "number": 3]
		if let dictionary = Defaults[any].get([String: Defaults.AnySerializable].self) {
			XCTAssertEqual(dictionary["unicorn"], "🦄")
			XCTAssertTrue(dictionary["boolean"]!.get(Bool.self)!)
			XCTAssertEqual(dictionary["number"], 3)
		}
		// Test Set
		Defaults[any].set(Set([1]))
		XCTAssertEqual(Defaults[any].get(Set<Int>.self)?.first, 1)
		// Test URL
		Defaults[any].set(URL(string: "https://example.com")!)
		XCTAssertEqual(Defaults[any].get()!, URL(string: "https://example.com")!)
		#if os(macOS)
		// Test NSColor
		Defaults[any].set(NSColor(red: CGFloat(103) / CGFloat(0xFF), green: CGFloat(132) / CGFloat(0xFF), blue: CGFloat(255) / CGFloat(0xFF), alpha: 0.987))
		XCTAssertEqual(Defaults[any].get(NSColor.self)?.alphaComponent, 0.987)
		#else
		// Test UIColor
		Defaults[any].set(UIColor(red: CGFloat(103) / CGFloat(0xFF), green: CGFloat(132) / CGFloat(0xFF), blue: CGFloat(255) / CGFloat(0xFF), alpha: 0.654))
		XCTAssertEqual(Defaults[any].get(UIColor.self)?.cgColor.alpha, 0.654)
		#endif
		// Test Codable type
		Defaults[any].set(CodableUnicorn(is_missing: false))
		XCTAssertFalse(Defaults[any].get(CodableUnicorn.self)!.is_missing)
		// Test Custom type
		Defaults[any].set(Unicorn(is_missing: true))
		XCTAssertTrue(Defaults[any].get(Unicorn.self)!.is_missing)
		// Test nil
		Defaults[any] = nil
		XCTAssertEqual(Defaults[any], 121_314)
	}

	func testOptionalKey() {
		let key = Defaults.Key<Defaults.AnySerializable?>("independentOptionalAnyKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = 12_131.4
		XCTAssertEqual(Defaults[key], 12_131.4)
		Defaults[key]?.set(mime.JSON)
		XCTAssertEqual(Defaults[key]?.get(mime.self), mime.JSON)
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
	}

	func testArrayKey() {
		let key = Defaults.Key<[Defaults.AnySerializable]>("independentArrayAnyKey", default: [123, 456])
		XCTAssertEqual(Defaults[key][0], 123)
		XCTAssertEqual(Defaults[key][1], 456)
		Defaults[key][0] = 12_131.4
		XCTAssertEqual(Defaults[key][0], 12_131.4)
	}

	func testSetKey() {
		let key = Defaults.Key<Set<Defaults.AnySerializable>>("independentArrayAnyKey", default: [123])
		XCTAssertEqual(Defaults[key].first, 123)
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

		let float = Defaults.AnySerializable(Float(1213.14))
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
		XCTAssertEqual(Defaults[key]![0], 123)
		XCTAssertEqual(Defaults[key]![1], 456)
		Defaults[key]![0] = 12_131.4
		XCTAssertEqual(Defaults[key]![0], 12_131.4)
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[Defaults.AnySerializable]]>("testNestedArrayAnyKey", default: [[123]])
		Defaults[key][0].append(456)
		XCTAssertEqual(Defaults[key][0][0], 123)
		XCTAssertEqual(Defaults[key][0][1], 456)
		Defaults[key].append([12_131.4])
		XCTAssertEqual(Defaults[key][1][0], 12_131.4)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]>("independentDictionaryAnyKey", default: ["unicorn": ""])
		XCTAssertEqual(Defaults[key]["unicorn"], "")
		Defaults[key]["unicorn"] = "🦄"
		XCTAssertEqual(Defaults[key]["unicorn"], "🦄")
		Defaults[key]["number"] = 3
		Defaults[key]["boolean"] = true
		XCTAssertEqual(Defaults[key]["number"], 3)
		if let bool: Bool = Defaults[.magic]["unicorn"]?.get() {
			XCTAssertTrue(bool)
		}
		Defaults[key]["set"] = Defaults.AnySerializable(Set([1]))
		XCTAssertEqual(Defaults[key]["set"]!.get(Set<Int>.self)!.first, 1)
		Defaults[key]["nil"] = nil
		XCTAssertNil(Defaults[key]["nil"])
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]?>("independentDictionaryOptionalAnyKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["unicorn": "🦄"]
		XCTAssertEqual(Defaults[key]?["unicorn"], "🦄")
		Defaults[key]?["number"] = 3
		Defaults[key]?["boolean"] = true
		XCTAssertEqual(Defaults[key]?["number"], 3)
		XCTAssertEqual(Defaults[key]?["boolean"], true)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Defaults.AnySerializable]]>("independentDictionaryArrayAnyKey", default: ["number": [1]])
		XCTAssertEqual(Defaults[key]["number"]?[0], 1)
		Defaults[key]["number"]?.append(2)
		Defaults[key]["unicorn"] = ["No.1 🦄"]
		Defaults[key]["unicorn"]?.append("No.2 🦄")
		Defaults[key]["unicorn"]?.append("No.3 🦄")
		Defaults[key]["boolean"] = [true]
		Defaults[key]["boolean"]?.append(false)
		XCTAssertEqual(Defaults[key]["number"]?[1], 2)
		XCTAssertEqual(Defaults[key]["unicorn"]?[0], "No.1 🦄")
		XCTAssertEqual(Defaults[key]["unicorn"]?[1], "No.2 🦄")
		XCTAssertEqual(Defaults[key]["unicorn"]?[2], "No.3 🦄")
		XCTAssertTrue(Defaults[key]["boolean"]![0].get(Bool.self)!)
		XCTAssertFalse(Defaults[key]["boolean"]![1].get(Bool.self)!)
	}

	func testType() {
		XCTAssertEqual(Defaults[.anyKey], "🦄")
		Defaults[.anyKey] = 123
		XCTAssertEqual(Defaults[.anyKey], 123)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.anyArrayKey][0], "No.1 🦄")
		XCTAssertEqual(Defaults[.anyArrayKey][1], "No.2 🦄")
		Defaults[.anyArrayKey].append(123)
		XCTAssertEqual(Defaults[.anyArrayKey][2], 123)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.anyDictionaryKey]["unicorn"], "🦄")
		Defaults[.anyDictionaryKey]["number"] = 3
		XCTAssertEqual(Defaults[.anyDictionaryKey]["number"], 3)
		Defaults[.anyDictionaryKey]["boolean"] = true
		XCTAssertTrue(Defaults[.anyDictionaryKey]["boolean"]!.get(Bool.self)!)
		Defaults[.anyDictionaryKey]["array"] = [1, 2]
		if let array = Defaults[.anyDictionaryKey]["array"]?.get([Int].self) {
			XCTAssertEqual(array[0], 1)
			XCTAssertEqual(array[1], 2)
		}
	}

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
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = "🦄"
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

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
				if tuples[index].0?.get(Int.self) != nil {
					XCTAssertEqual(expected.0, tuples[index].0)
					XCTAssertEqual(expected.1, tuples[index].1)
				} else if tuples[index].0?.get(String.self) != nil {
					XCTAssertEqual(expected.0, tuples[index].0)
					XCTAssertNil(tuples[index].1)
				} else {
					XCTAssertNil(tuples[index].0)
					XCTAssertEqual(expected.1, tuples[index].1)
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
			XCTAssertEqual(change.oldValue, 123)
			XCTAssertEqual(change.newValue, "🦄")
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
			XCTAssertEqual(change.newValue, "🦄")
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = "🦄"
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

    func testWrongCast() {
        let value = Defaults.AnySerializable(false)
        XCTAssertEqual(value.get(Bool.self), false)
        XCTAssertNil(value.get(String.self))
    }
}
