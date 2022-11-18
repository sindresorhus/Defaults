import Foundation
import Defaults
import XCTest

public struct User: Hashable, Equatable {
	var username: String
	var password: String
}

extension User: Defaults.Serializable {
	public static let bridge = DefaultsUserBridge()
}

public final class DefaultsUserBridge: Defaults.Bridge {
	public typealias Value = User
	public typealias Serializable = [String: String]

	public func serialize(_ value: Value?) -> Serializable? {
		guard let value else {
			return nil
		}

		return ["username": value.username, "password": value.password]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object,
			let username = object["username"],
			let password = object["password"]
		else {
			return nil
		}

		return User(username: username, password: password)
	}
}

private let fixtureCustomBridge = User(username: "hank121314", password: "123456")

struct PlainHourMinuteTimeRange: Hashable, Codable {
	var start: PlainHourMinuteTime
	var end: PlainHourMinuteTime
}

extension PlainHourMinuteTimeRange: Defaults.Serializable {
	struct Bridge: Defaults.Bridge {
		typealias Value = PlainHourMinuteTimeRange
		typealias Serializable = [PlainHourMinuteTime]

		func serialize(_ value: Value?) -> Serializable? {
			guard let value = value else {
				return nil
			}

			return [value.start, value.end]
		}

		func deserialize(_ object: Serializable?) -> Value? {
			guard
				let array = object,
				let start = array[safe: 0],
				let end = array[safe: 1]
			else {
				return nil
			}

			return .init(start: start, end: end)
		}
	}

	static let bridge = Bridge()
}

struct PlainHourMinuteTime: Hashable, Codable, Defaults.Serializable {
	var hour: Int
	var minute: Int
}

extension Collection {
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension Defaults.Keys {
	fileprivate static let customBridge = Key<User>("customBridge", default: fixtureCustomBridge)
	fileprivate static let customBridgeArray = Key<[User]>("array_customBridge", default: [fixtureCustomBridge])
	fileprivate static let customBridgeDictionary = Key<[String: User]>("dictionary_customBridge", default: ["0": fixtureCustomBridge])
}

final class DefaultsCustomBridge: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<User>("independentCustomBridgeKey", default: fixtureCustomBridge)
		XCTAssertEqual(Defaults[key], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key] = newUser
		XCTAssertEqual(Defaults[key], newUser)
	}

	func testOptionalKey() {
		let key = Defaults.Key<User?>("independentCustomBridgeOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureCustomBridge
		XCTAssertEqual(Defaults[key], fixtureCustomBridge)
	}

	func testArrayKey() {
		let user = User(username: "hank121314", password: "123456")
		let key = Defaults.Key<[User]>("independentCustomBridgeArrayKey", default: [user])
		XCTAssertEqual(Defaults[key][0], user)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key][0] = newUser
		XCTAssertEqual(Defaults[key][0], newUser)
	}

	func testArrayOptionalKey() {
		let key = Defaults.Key<[User]?>("independentCustomBridgeArrayOptionalKey")
		XCTAssertNil(Defaults[key])
		let newUser = User(username: "hank121314", password: "123456")
		Defaults[key] = [newUser]
		XCTAssertEqual(Defaults[key]?[0], newUser)
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
	}

	func testNestedArrayKey() {
		let key = Defaults.Key<[[User]]>("independentCustomBridgeNestedArrayKey", default: [[fixtureCustomBridge], [fixtureCustomBridge]])
		XCTAssertEqual(Defaults[key][0][0].username, fixtureCustomBridge.username)
		let newUsername = "John"
		let newPassword = "7891011"
		Defaults[key][0][0] = User(username: newUsername, password: newPassword)
		XCTAssertEqual(Defaults[key][0][0].username, newUsername)
		XCTAssertEqual(Defaults[key][0][0].password, newPassword)
		XCTAssertEqual(Defaults[key][1][0].username, fixtureCustomBridge.username)
		XCTAssertEqual(Defaults[key][1][0].password, fixtureCustomBridge.password)
	}

	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: User]]>("independentCustomBridgeArrayDictionaryKey", default: [["0": fixtureCustomBridge], ["0": fixtureCustomBridge]])
		XCTAssertEqual(Defaults[key][0]["0"]?.username, fixtureCustomBridge.username)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key][0]["0"] = newUser
		XCTAssertEqual(Defaults[key][0]["0"], newUser)
		XCTAssertEqual(Defaults[key][1]["0"], fixtureCustomBridge)
	}

	func testSetKey() {
		let key = Defaults.Key<Set<User>>("independentCustomBridgeSetKey", default: [fixtureCustomBridge])
		XCTAssertEqual(Defaults[key].first, fixtureCustomBridge)
		Defaults[key].insert(fixtureCustomBridge)
		XCTAssertEqual(Defaults[key].count, 1)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key].insert(newUser)
		XCTAssertTrue(Defaults[key].contains(newUser))
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[String: User]>("independentCustomBridgeDictionaryKey", default: ["0": fixtureCustomBridge])
		XCTAssertEqual(Defaults[key]["0"], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key]["0"] = newUser
		XCTAssertEqual(Defaults[key]["0"], newUser)
	}

	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: User]?>("independentCustomBridgeDictionaryOptionalKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = ["0": fixtureCustomBridge]
		XCTAssertEqual(Defaults[key]?["0"], fixtureCustomBridge)
	}

	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [User]]>("independentCustomBridgeDictionaryArrayKey", default: ["0": [fixtureCustomBridge]])
		XCTAssertEqual(Defaults[key]["0"]?[0], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key]["0"]?[0] = newUser
		Defaults[key]["0"]?.append(fixtureCustomBridge)
		XCTAssertEqual(Defaults[key]["0"]?[0], newUser)
		XCTAssertEqual(Defaults[key]["0"]?[0], newUser)
		XCTAssertEqual(Defaults[key]["0"]?[1], fixtureCustomBridge)
		XCTAssertEqual(Defaults[key]["0"]?[1], fixtureCustomBridge)
	}

	func testRecursiveKey() {
		let start = PlainHourMinuteTime(hour: 1, minute: 0)
		let end = PlainHourMinuteTime(hour: 2, minute: 0)
		let range = PlainHourMinuteTimeRange(start: start, end: end)
		let key = Defaults.Key<PlainHourMinuteTimeRange>("independentCustomBridgeRecursiveKey", default: range)
		XCTAssertEqual(Defaults[key].start.hour, range.start.hour)
		XCTAssertEqual(Defaults[key].start.minute, range.start.minute)
		XCTAssertEqual(Defaults[key].end.hour, range.end.hour)
		XCTAssertEqual(Defaults[key].end.minute, range.end.minute)
		guard let rawValue = UserDefaults.standard.array(forKey: key.name) as? [String] else {
			XCTFail("rawValue should not be nil")
			return
		}
		XCTAssertEqual(rawValue, [#"{"minute":0,"hour":1}"#, #"{"minute":0,"hour":2}"#])
		let next_start = PlainHourMinuteTime(hour: 3, minute: 58)
		let next_end = PlainHourMinuteTime(hour: 4, minute: 59)
		let next_range = PlainHourMinuteTimeRange(start: next_start, end: next_end)
		Defaults[key] = next_range
		XCTAssertEqual(Defaults[key].start.hour, next_range.start.hour)
		XCTAssertEqual(Defaults[key].start.minute, next_range.start.minute)
		XCTAssertEqual(Defaults[key].end.hour, next_range.end.hour)
		XCTAssertEqual(Defaults[key].end.minute, next_range.end.minute)
		guard let nextRawValue = UserDefaults.standard.array(forKey: key.name) as? [String] else {
			XCTFail("nextRawValue should not be nil")
			return
		}
		XCTAssertEqual(nextRawValue, [#"{"minute":58,"hour":3}"#, #"{"minute":59,"hour":4}"#])
	}

	func testType() {
		XCTAssertEqual(Defaults[.customBridge], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridge] = newUser
		XCTAssertEqual(Defaults[.customBridge], newUser)
	}

	func testArrayType() {
		XCTAssertEqual(Defaults[.customBridgeArray][0], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridgeArray][0] = newUser
		XCTAssertEqual(Defaults[.customBridgeArray][0], newUser)
	}

	func testDictionaryType() {
		XCTAssertEqual(Defaults[.customBridgeDictionary]["0"], fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridgeDictionary]["0"] = newUser
		XCTAssertEqual(Defaults[.customBridgeDictionary]["0"], newUser)
	}

	func testObserveKeyCombine() {
		let key = Defaults.Key<User>("observeCustomBridgeKeyCombine", default: fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCustomBridge, newUser), (newUser, fixtureCustomBridge)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = newUser
		Defaults[key] = fixtureCustomBridge
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<User?>("observeCustomBridgeOptionalKeyCombine")
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValue: [(User?, User?)] = [(nil, fixtureCustomBridge), (fixtureCustomBridge, newUser), (newUser, nil)]

		let cancellable = publisher.sink { tuples in
			for (index, expected) in expectedValue.enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureCustomBridge
		Defaults[key] = newUser
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKeyCombine() {
		let key = Defaults.Key<[User]>("observeCustomBridgeArrayKeyCombine", default: [fixtureCustomBridge])
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [([fixtureCustomBridge], [newUser]), ([newUser], [newUser, fixtureCustomBridge])].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key][0] = newUser
		Defaults[key].append(fixtureCustomBridge)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryCombine() {
		let key = Defaults.Key<[String: User]>("observeCustomBridgeDictionaryKeyCombine", default: ["0": fixtureCustomBridge])
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(fixtureCustomBridge, newUser), (newUser, fixtureCustomBridge)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0["0"])
				XCTAssertEqual(expected.1, tuples[index].1["0"])
			}

			expect.fulfill()
		}

		Defaults[key]["0"] = newUser
		Defaults[key]["0"] = fixtureCustomBridge
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<User>("observeCustomBridgeKey", default: fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, fixtureCustomBridge)
			XCTAssertEqual(change.newValue, newUser)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = newUser
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<User?>("observeCustomBridgeOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue, fixtureCustomBridge)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureCustomBridge
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveArrayKey() {
		let key = Defaults.Key<[User]>("observeCustomBridgeArrayKey", default: [fixtureCustomBridge])
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue[0], fixtureCustomBridge)
			XCTAssertEqual(change.newValue[0], newUser)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][0] = newUser
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveDictionaryKey() {
		let key = Defaults.Key<[String: User]>("observeCustomBridgeDictionaryKey", default: ["0": fixtureCustomBridge])
		let newUser = User(username: "sindresorhus", password: "123456789")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue["0"], fixtureCustomBridge)
			XCTAssertEqual(change.newValue["0"], newUser)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key]["0"] = newUser
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}
}
