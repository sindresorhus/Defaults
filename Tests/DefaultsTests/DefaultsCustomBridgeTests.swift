import Foundation
import Testing
import Defaults

private let suite_ = createSuite()

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
			guard let value else {
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
	fileprivate static let customBridge = Key<User>("customBridge", default: fixtureCustomBridge, suite: suite_)
	fileprivate static let customBridgeArray = Key<[User]>("array_customBridge", default: [fixtureCustomBridge], suite: suite_)
	fileprivate static let customBridgeDictionary = Key<[String: User]>("dictionary_customBridge", default: ["0": fixtureCustomBridge], suite: suite_)
}

@Suite(.serialized)
final class DefaultsCustomBridge {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<User>("independentCustomBridgeKey", default: fixtureCustomBridge, suite: suite_)
		#expect(Defaults[key] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key] = newUser
		#expect(Defaults[key] == newUser)
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<User?>("independentCustomBridgeOptionalKey", suite: suite_)
		#expect(Defaults[key] == nil)
		Defaults[key] = fixtureCustomBridge
		#expect(Defaults[key] == fixtureCustomBridge)
	}

	@Test
	func testArrayKey() {
		let user = User(username: "hank121314", password: "123456")
		let key = Defaults.Key<[User]>("independentCustomBridgeArrayKey", default: [user], suite: suite_)
		#expect(Defaults[key][0] == user)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key][0] = newUser
		#expect(Defaults[key][0] == newUser)
	}

	@Test
	func testArrayOptionalKey() {
		let key = Defaults.Key<[User]?>("independentCustomBridgeArrayOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		let newUser = User(username: "hank121314", password: "123456")
		Defaults[key] = [newUser]
		#expect(Defaults[key]?[0] == newUser)
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
	}

	@Test
	func testNestedArrayKey() {
		let key = Defaults.Key<[[User]]>("independentCustomBridgeNestedArrayKey", default: [[fixtureCustomBridge], [fixtureCustomBridge]], suite: suite_)
		#expect(Defaults[key][0][0].username == fixtureCustomBridge.username)
		let newUsername = "John"
		let newPassword = "7891011"
		Defaults[key][0][0] = User(username: newUsername, password: newPassword)
		#expect(Defaults[key][0][0].username == newUsername)
		#expect(Defaults[key][0][0].password == newPassword)
		#expect(Defaults[key][1][0].username == fixtureCustomBridge.username)
		#expect(Defaults[key][1][0].password == fixtureCustomBridge.password)
	}

	@Test
	func testArrayDictionaryKey() {
		let key = Defaults.Key<[[String: User]]>("independentCustomBridgeArrayDictionaryKey", default: [["0": fixtureCustomBridge], ["0": fixtureCustomBridge]], suite: suite_)
		#expect(Defaults[key][0]["0"]?.username == fixtureCustomBridge.username)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key][0]["0"] = newUser
		#expect(Defaults[key][0]["0"] == newUser)
		#expect(Defaults[key][1]["0"] == fixtureCustomBridge)
	}

	@Test
	func testSetKey() {
		let key = Defaults.Key<Set<User>>("independentCustomBridgeSetKey", default: [fixtureCustomBridge], suite: suite_)
		#expect(Defaults[key].first == fixtureCustomBridge)
		Defaults[key].insert(fixtureCustomBridge)
		#expect(Defaults[key].count == 1)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key].insert(newUser)
		#expect(Defaults[key].contains(newUser))
	}

	@Test
	func testDictionaryKey() {
		let key = Defaults.Key<[String: User]>("independentCustomBridgeDictionaryKey", default: ["0": fixtureCustomBridge], suite: suite_)
		#expect(Defaults[key]["0"] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key]["0"] = newUser
		#expect(Defaults[key]["0"] == newUser)
	}

	@Test
	func testDictionaryOptionalKey() {
		let key = Defaults.Key<[String: User]?>("independentCustomBridgeDictionaryOptionalKey", suite: suite_) // swiftlint:disable:this discouraged_optional_collection
		#expect(Defaults[key] == nil)
		Defaults[key] = ["0": fixtureCustomBridge]
		#expect(Defaults[key]?["0"] == fixtureCustomBridge)
	}

	@Test
	func testDictionaryArrayKey() {
		let key = Defaults.Key<[String: [User]]>("independentCustomBridgeDictionaryArrayKey", default: ["0": [fixtureCustomBridge]], suite: suite_)
		#expect(Defaults[key]["0"]?[0] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[key]["0"]?[0] = newUser
		Defaults[key]["0"]?.append(fixtureCustomBridge)
		#expect(Defaults[key]["0"]?[0] == newUser)
		#expect(Defaults[key]["0"]?[0] == newUser)
		#expect(Defaults[key]["0"]?[1] == fixtureCustomBridge)
		#expect(Defaults[key]["0"]?[1] == fixtureCustomBridge)
	}

	@Test
	func testRecursiveKey() {
		let start = PlainHourMinuteTime(hour: 1, minute: 0)
		let end = PlainHourMinuteTime(hour: 2, minute: 0)
		let range = PlainHourMinuteTimeRange(start: start, end: end)
		let key = Defaults.Key<PlainHourMinuteTimeRange>("independentCustomBridgeRecursiveKey", default: range, suite: suite_)
		#expect(Defaults[key].start.hour == range.start.hour)
		#expect(Defaults[key].start.minute == range.start.minute)
		#expect(Defaults[key].end.hour == range.end.hour)
		#expect(Defaults[key].end.minute == range.end.minute)
		guard let rawValue = suite_.array(forKey: key.name) as? [String] else {
			Issue.record("rawValue should not be nil")
			return
		}
		#expect(rawValue == [#"{"hour":1,"minute":0}"#, #"{"hour":2,"minute":0}"#])
		let next_start = PlainHourMinuteTime(hour: 3, minute: 58)
		let next_end = PlainHourMinuteTime(hour: 4, minute: 59)
		let next_range = PlainHourMinuteTimeRange(start: next_start, end: next_end)
		Defaults[key] = next_range
		#expect(Defaults[key].start.hour == next_range.start.hour)
		#expect(Defaults[key].start.minute == next_range.start.minute)
		#expect(Defaults[key].end.hour == next_range.end.hour)
		#expect(Defaults[key].end.minute == next_range.end.minute)

		guard let nextRawValue = suite_.array(forKey: key.name) as? [String] else {
			Issue.record("nextRawValue should not be nil")
			return
		}

		#expect(nextRawValue == [#"{"hour":3,"minute":58}"#, #"{"hour":4,"minute":59}"#])
	}

	@Test
	func testType() {
		#expect(Defaults[.customBridge] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridge] = newUser
		#expect(Defaults[.customBridge] == newUser)
	}

	@Test
	func testArrayType() {
		#expect(Defaults[.customBridgeArray][0] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridgeArray][0] = newUser
		#expect(Defaults[.customBridgeArray][0] == newUser)
	}

	@Test
	func testDictionaryType() {
		#expect(Defaults[.customBridgeDictionary]["0"] == fixtureCustomBridge)
		let newUser = User(username: "sindresorhus", password: "123456789")
		Defaults[.customBridgeDictionary]["0"] = newUser
		#expect(Defaults[.customBridgeDictionary]["0"] == newUser)
	}
}
