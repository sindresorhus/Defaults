import SwiftUI
import Testing
import Defaults

private let suite_ = createSuite()

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
	fileprivate static let magic = Key<[String: Defaults.AnySerializable]>("magic", default: [:], suite: suite_)
	fileprivate static let anyKey = Key<Defaults.AnySerializable>("anyKey", default: "🦄", suite: suite_)
	fileprivate static let anyArrayKey = Key<[Defaults.AnySerializable]>("anyArrayKey", default: ["No.1 🦄", "No.2 🦄"], suite: suite_)
	fileprivate static let anyDictionaryKey = Key<[String: Defaults.AnySerializable]>("anyDictionaryKey", default: ["unicorn": "🦄"], suite: suite_)
}

@Suite(.serialized)
final class DefaultsAnySerializableTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testReadMeExample() {
		let any = Defaults.Key<Defaults.AnySerializable>("anyKey", default: Defaults.AnySerializable(mime.JSON), suite: suite_)
		if let mimeType: mime = Defaults[any].get() {
			#expect(mimeType == mime.JSON)
		}
		Defaults[any].set(mime.STREAM)
		if let mimeType: mime = Defaults[any].get() {
			#expect(mimeType == mime.STREAM)
		}
		Defaults[any].set(mime.JSON)
		if let mimeType: mime = Defaults[any].get() {
			#expect(mimeType == mime.JSON)
		}
		Defaults[.magic]["unicorn"] = "🦄"
		Defaults[.magic]["number"] = 3
		Defaults[.magic]["boolean"] = true
		Defaults[.magic]["enum"] = Defaults.AnySerializable(mime.JSON)
		#expect(Defaults[.magic]["unicorn"] == "🦄")
		#expect(Defaults[.magic]["number"] == 3)
		if let bool: Bool = Defaults[.magic]["unicorn"]?.get() {
			#expect(bool)
		}
		#expect(Defaults[.magic]["enum"]?.get() == mime.JSON)
		Defaults[.magic]["enum"]?.set(mime.STREAM)
		if let value: String = Defaults[.magic]["unicorn"]?.get() {
			#expect(value == "🦄")
		}
		if let mimeType: mime = Defaults[.magic]["enum"]?.get() {
			#expect(mimeType == mime.STREAM)
		}
		Defaults[any].set(mime.JSON)
		if let mimeType: mime = Defaults[any].get() {
			#expect(mime.JSON == mimeType)
		}
		Defaults[any].set(mime.STREAM)
		if let mimeType: mime = Defaults[any].get() {
			#expect(mime.STREAM == mimeType)
		}
	}

	@Test
	func testKey() {
		// Test Int
		let any = Defaults.Key<Defaults.AnySerializable>("independentAnyKey", default: 121_314, suite: suite_)
		#expect(Defaults[any] == 121_314)
		// Test Int8
		let int8 = Int8.max
		Defaults[any].set(int8)
		#expect(Defaults[any].get() == int8)
		// Test Int16
		let int16 = Int16.max
		Defaults[any].set(int16)
		#expect(Defaults[any].get() == int16)
		// Test Int32
		let int32 = Int32.max
		Defaults[any].set(int32)
		#expect(Defaults[any].get() == int32)
		// Test Int64
		let int64 = Int64.max
		Defaults[any].set(int64)
		#expect(Defaults[any].get() == int64)
		// Test UInt
		let uint = UInt.max
		Defaults[any].set(uint)
		#expect(Defaults[any].get() == uint)
		// Test UInt8
		let uint8 = UInt8.max
		Defaults[any].set(uint8)
		#expect(Defaults[any].get() == uint8)
		// Test UInt16
		let uint16 = UInt16.max
		Defaults[any].set(uint16)
		#expect(Defaults[any].get() == uint16)
		// Test UInt32
		let uint32 = UInt32.max
		Defaults[any].set(uint32)
		#expect(Defaults[any].get() == uint32)
		// Test UInt64
		let uint64 = UInt64.max
		Defaults[any].set(uint64)
		#expect(Defaults[any].get() == uint64)
		// Test Double
		Defaults[any] = 12_131.4
		#expect(Defaults[any] == 12_131.4)
		// Test Bool
		Defaults[any] = true
		#expect(Defaults[any].get(Bool.self)!)
		// Test String
		Defaults[any] = "121314"
		#expect(Defaults[any] == "121314")
		// Test Float
		Defaults[any].set(12_131.456, type: Float.self)
		#expect(Defaults[any].get(Float.self) == 12_131.456)
		// Test Date
		let date = Date()
		Defaults[any].set(date)
		#expect(Defaults[any].get(Date.self) == date)
		// Test Data
		let data = "121314".data(using: .utf8)
		Defaults[any].set(data)
		#expect(Defaults[any].get(Data.self) == data)
		// Test Array
		Defaults[any] = [1, 2, 3]
		if let array: [Int] = Defaults[any].get() {
			#expect(array[0] == 1)
			#expect(array[1] == 2)
			#expect(array[2] == 3)
		}
		// Test Dictionary
		Defaults[any] = ["unicorn": "🦄", "boolean": true, "number": 3]
		if let dictionary = Defaults[any].get([String: Defaults.AnySerializable].self) {
			#expect(dictionary["unicorn"] == "🦄")
			#expect(dictionary["boolean"]?.get(Bool.self) == true)
			#expect(dictionary["number"] == 3)
		}
		// Test Set
		Defaults[any].set(Set([1]))
		#expect(Defaults[any].get(Set<Int>.self)?.first == 1)
		// Test URL
		Defaults[any].set(URL(string: "https://example.com")!)
		#expect(Defaults[any].get()! == URL(string: "https://example.com")!)
		#if os(macOS)
		// Test NSColor
		Defaults[any].set(NSColor(red: Double(103) / Double(0xFF), green: Double(132) / Double(0xFF), blue: Double(255) / Double(0xFF), alpha: 0.987))
		#expect(Defaults[any].get(NSColor.self)?.alphaComponent == 0.987)
		#else
		// Test UIColor
		Defaults[any].set(UIColor(red: Double(103) / Double(0xFF), green: Double(132) / Double(0xFF), blue: Double(255) / Double(0xFF), alpha: 0.654))
		#expect(Defaults[any].get(UIColor.self)?.cgColor.alpha == 0.654)
		#endif
		// Test Codable type
		Defaults[any].set(CodableUnicorn(is_missing: false))
		#expect(Defaults[any].get(CodableUnicorn.self)!.is_missing == false)
		// Test Custom type
		Defaults[any].set(Unicorn(is_missing: true))
		#expect(Defaults[any].get(Unicorn.self)!.is_missing)
		// Test nil
		Defaults[any] = nil
		#expect(Defaults[any] == 121_314)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Defaults.AnySerializable?>("independentOptionalAnyKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = 12_131.4
		#expect(Defaults[key] == 12_131.4)
		Defaults[key]?.set(mime.JSON)
		#expect(Defaults[key]?.get(mime.self) == mime.JSON)
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
	}

	@Test
	func testArrayKey() {
		let key = Defaults.Key<[Defaults.AnySerializable]>("independentArrayAnyKey", default: [123, 456], suite: suite_)
		#expect(Defaults[key][0] == 123)
		#expect(Defaults[key][1] == 456)
		Defaults[key][0] = 12_131.4
		#expect(Defaults[key][0] == 12_131.4)
	}

	@Test
	func testSetKey() {
		let key = Defaults.Key<Set<Defaults.AnySerializable>>("independentArrayAnyKey", default: [123], suite: suite_)
		#expect(Defaults[key].first == 123)
		Defaults[key].insert(12_131.4)
		#expect(Defaults[key].contains(12_131.4))
		let date = Defaults.AnySerializable(Date())
		Defaults[key].insert(date)
		#expect(Defaults[key].contains(date))
		let data = Defaults.AnySerializable("Hello World!".data(using: .utf8))
		Defaults[key].insert(data)
		#expect(Defaults[key].contains(data))
		let int = Defaults.AnySerializable(Int.max)
		Defaults[key].insert(int)
		#expect(Defaults[key].contains(int))
		let int8 = Defaults.AnySerializable(Int8.max)
		Defaults[key].insert(int8)
		#expect(Defaults[key].contains(int8))
		let int16 = Defaults.AnySerializable(Int16.max)
		Defaults[key].insert(int16)
		#expect(Defaults[key].contains(int16))
		let int32 = Defaults.AnySerializable(Int32.max)
		Defaults[key].insert(int32)
		#expect(Defaults[key].contains(int32))
		let int64 = Defaults.AnySerializable(Int64.max)
		Defaults[key].insert(int64)
		#expect(Defaults[key].contains(int64))
		let uint = Defaults.AnySerializable(UInt.max)
		Defaults[key].insert(uint)
		#expect(Defaults[key].contains(uint))
		let uint8 = Defaults.AnySerializable(UInt8.max)
		Defaults[key].insert(uint8)
		#expect(Defaults[key].contains(uint8))
		let uint16 = Defaults.AnySerializable(UInt16.max)
		Defaults[key].insert(uint16)
		#expect(Defaults[key].contains(uint16))
		let uint32 = Defaults.AnySerializable(UInt32.max)
		Defaults[key].insert(uint32)
		#expect(Defaults[key].contains(uint32))
		let uint64 = Defaults.AnySerializable(UInt64.max)
		Defaults[key].insert(uint64)
		#expect(Defaults[key].contains(uint64))

		let bool: Defaults.AnySerializable = false
		Defaults[key].insert(bool)
		#expect(Defaults[key].contains(bool))

		let float = Defaults.AnySerializable(Float(1213.14))
		Defaults[key].insert(float)
		#expect(Defaults[key].contains(float))

		let cgFloat = Defaults.AnySerializable(CGFloat(12_131.415)) // swiftlint:disable:this no_cgfloat2
		Defaults[key].insert(cgFloat)
		#expect(Defaults[key].contains(cgFloat))

		let string = Defaults.AnySerializable("Hello World!")
		Defaults[key].insert(string)
		#expect(Defaults[key].contains(string))

		let array: Defaults.AnySerializable = [1, 2, 3, 4]
		Defaults[key].insert(array)
		#expect(Defaults[key].contains(array))

		let dictionary: Defaults.AnySerializable = ["Hello": "World!"]
		Defaults[key].insert(dictionary)
		#expect(Defaults[key].contains(dictionary))

		let unicorn = Defaults.AnySerializable(Unicorn(is_missing: true))
		Defaults[key].insert(unicorn)
		#expect(Defaults[key].contains(unicorn))
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[Defaults.AnySerializable]?>("testArrayOptionalAnyKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = [123]
		Defaults[key]?.append(456)
		#expect(Defaults[key]![0] == 123)
		#expect(Defaults[key]![1] == 456)
		Defaults[key]![0] = 12_131.4
		#expect(Defaults[key]![0] == 12_131.4)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[Defaults.AnySerializable]]>("testNestedArrayAnyKey", default: [[123]], suite: suite_)
		Defaults[key][0].append(456)
		#expect(Defaults[key][0][0] == 123)
		#expect(Defaults[key][0][1] == 456)
		Defaults[key].append([12_131.4])
		#expect(Defaults[key][1][0] == 12_131.4)
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]>("independentDictionaryAnyKey", default: ["unicorn": ""], suite: suite_)
		#expect(Defaults[key]["unicorn"] == "") // swiftlint:disable:this empty_string
		Defaults[key]["unicorn"] = "🦄"
		#expect(Defaults[key]["unicorn"] == "🦄")
		Defaults[key]["number"] = 3
		Defaults[key]["boolean"] = true
		#expect(Defaults[key]["number"] == 3)
		if let bool: Bool = Defaults[.magic]["unicorn"]?.get() {
			#expect(bool)
		}
		Defaults[key]["set"] = Defaults.AnySerializable(Set([1]))
		#expect(Defaults[key]["set"]!.get(Set<Int>.self)!.first == 1)
		Defaults[key]["nil"] = nil
		#expect(Defaults[key]["nil"] == nil)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: Defaults.AnySerializable]?>("independentDictionaryOptionalAnyKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["unicorn": "🦄"]
		#expect(Defaults[key]?["unicorn"] == "🦄")
		Defaults[key]?["number"] = 3
		Defaults[key]?["boolean"] = true
		#expect(Defaults[key]?["number"] == 3)
		#expect(Defaults[key]?["boolean"] == true)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [Defaults.AnySerializable]]>("independentDictionaryArrayAnyKey", default: ["number": [1]], suite: suite_)
		#expect(Defaults[key]["number"]?[0] == 1)
		Defaults[key]["number"]?.append(2)
		Defaults[key]["unicorn"] = ["No.1 🦄"]
		Defaults[key]["unicorn"]?.append("No.2 🦄")
		Defaults[key]["unicorn"]?.append("No.3 🦄")
		Defaults[key]["boolean"] = [true]
		Defaults[key]["boolean"]?.append(false)
		#expect(Defaults[key]["number"]?[1] == 2)
		#expect(Defaults[key]["unicorn"]?[0] == "No.1 🦄")
		#expect(Defaults[key]["unicorn"]?[1] == "No.2 🦄")
		#expect(Defaults[key]["unicorn"]?[2] == "No.3 🦄")
//		#expect(#require(Defaults[key]["boolean"]?[0].get(Bool.self)) == true)
		#expect(Defaults[key]["boolean"]?[1].get(Bool.self) == false)
	}

	@Test
	func testType() {
		#expect(Defaults[.anyKey] == "🦄")
		Defaults[.anyKey] = 123
		#expect(Defaults[.anyKey] == 123)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.anyArrayKey][0] == "No.1 🦄")
		#expect(Defaults[.anyArrayKey][1] == "No.2 🦄")
		Defaults[.anyArrayKey].append(123)
		#expect(Defaults[.anyArrayKey][2] == 123)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.anyDictionaryKey]["unicorn"] == "🦄")
		Defaults[.anyDictionaryKey]["number"] = 3
		#expect(Defaults[.anyDictionaryKey]["number"] == 3)
		Defaults[.anyDictionaryKey]["boolean"] = true
		#expect(Defaults[.anyDictionaryKey]["boolean"]!.get(Bool.self)!)
		Defaults[.anyDictionaryKey]["array"] = [1, 2]
		if let array = Defaults[.anyDictionaryKey]["array"]?.get([Int].self) {
			#expect(array[0] == 1)
			#expect(array[1] == 2)
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveKeyCombine() async {
		let key = Defaults.Key<Defaults.AnySerializable>("observeAnyKeyCombine", default: 123, suite: suite_)

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let expectedValue: [(Defaults.AnySerializable, Defaults.AnySerializable)] = [(123, "🦄"), ("🦄", 123)]

		Task {
			try? await Task.sleep(for: .seconds(0.1))
			Defaults[key] = "🦄"
			Defaults.reset(key)
		}

		for await tuples in publisher.values {
			for (index, expected) in expectedValue.enumerated() {
				#expect(expected.0 == tuples[index].0)
				#expect(expected.1 == tuples[index].1)
			}

			break
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveOptionalKeyCombine() async {
		let key = Defaults.Key<Defaults.AnySerializable?>("observeAnyOptionalKeyCombine", suite: suite_)

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(Defaults.AnySerializable?, Defaults.AnySerializable?)] = [(nil, 123), (123, "🦄"), ("🦄", nil)]

		Task {
			try? await Task.sleep(for: .seconds(0.1))
			Defaults[key] = 123
			Defaults[key] = "🦄"
			Defaults.reset(key)
		}

		for await tuples in publisher.values {
			for (index, expected) in expectedValue.enumerated() {
				if tuples[index].0?.get(Int.self) != nil {
					#expect(expected.0 == tuples[index].0)
					#expect(expected.1 == tuples[index].1)
				} else if tuples[index].0?.get(String.self) != nil {
					#expect(expected.0 == tuples[index].0)
					#expect(tuples[index].1 == nil)
				} else {
					#expect(tuples[index].0 == nil)
					#expect(expected.1 == tuples[index].1)
				}
			}
			break
		}
	}

	@Test
	func testWrongCast() {
		let value = Defaults.AnySerializable(false)
		#expect(value.get(Bool.self) == false)
		#expect(value.get(String.self) == nil)
	}
}
