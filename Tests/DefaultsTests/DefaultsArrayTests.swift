import Foundation
import Defaults
import XCTest

final class DefaultsArrayTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.setUp()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<[String]>("independentArrayStringKey", default: fixtureArray)
		XCTAssertEqual(Defaults[key][0], fixtureArray[0])
		let newValue = "John"
		Defaults[key][0] = newValue
		XCTAssertEqual(Defaults[key][0], newValue)
	}

	func testOptionalKey() {
		let key = Defaults.Key<[String]?>("independentArrayOptionalStringKey")
		XCTAssertNil(Defaults[key])
		Defaults[key] = fixtureArray
		XCTAssertEqual(Defaults[key]?[0], fixtureArray[0])
		Defaults[key] = nil
		XCTAssertNil(Defaults[key])
		let newValue = ["John", "Chen"]
		Defaults[key] = newValue
		XCTAssertEqual(Defaults[key]?[0], newValue[0])
	}

	func testCustomBridgeKey() {
		let username = "hank121314"
		let password = "123456"
		let key = Defaults.Key<[User]>("independentArrayCustomBridgeKey", default: [User(username: username , password: password)])
		XCTAssertEqual(Defaults[key][0].password, password)
		let newPassword = "7891011"
		Defaults[key][0] = User(username: username, password: newPassword)
		XCTAssertEqual(Defaults[key][0].password, newPassword)
	}

	func testNestedKey() {
		let key = Defaults.Key<[[User]]>("independentArrayNestedKey", default: [[fixtureCustomBridge], [fixtureCustomBridge]])
		XCTAssertEqual(Defaults[key][0][0].username, fixtureCustomBridge.username)
		let newUsername = "John"
		let newPassword = "7891011"
		Defaults[key][0][0] = User(username: newUsername, password: newPassword)
		XCTAssertEqual(Defaults[key][0][0].username, newUsername)
		XCTAssertEqual(Defaults[key][0][0].password, newPassword)
		XCTAssertEqual(Defaults[key][1][0].username, fixtureCustomBridge.username)
		XCTAssertEqual(Defaults[key][1][0].password, fixtureCustomBridge.password)
	}

	func testDictionaryKey() {
		let key = Defaults.Key<[[String: User]]>("independentArrayDictionaryKey", default: [["0": fixtureCustomBridge], ["0": fixtureCustomBridge]])
		XCTAssertEqual(Defaults[key][0]["0"]?.username, fixtureCustomBridge.username)
		let newUsername = "John"
		let newPassword = "7891011"
		Defaults[key][0]["0"] = User(username: newUsername, password: newPassword)
		XCTAssertEqual(Defaults[key][0]["0"]?.username, newUsername)
		XCTAssertEqual(Defaults[key][0]["0"]?.password, newPassword)
		XCTAssertEqual(Defaults[key][1]["0"]?.username, fixtureCustomBridge.username)
		XCTAssertEqual(Defaults[key][1]["0"]?.password, fixtureCustomBridge.password)
	}

	func testType() {
		XCTAssertEqual(Defaults[.array][0], fixtureArray[0])
		let newName = "Hank121314"
		Defaults[.array][0] = newName
		XCTAssertEqual(Defaults[.array][0], newName)
	}


	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<[String]>("observeArrayKeyCombine", default: fixtureArray)
		let expect = expectation(description: "Observation closure being called")
		let newName = "John"

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (i, expected) in [(fixtureArray[0], newName), (newName, fixtureArray[0])].enumerated() {
				XCTAssertEqual(expected.0, tuples[i].0[0])
				XCTAssertEqual(expected.1, tuples[i].1[0])
			}

			expect.fulfill()
		}

		Defaults[key][0] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<[String]?>("observeArrayOptionalKeyCombine")
		let expect = expectation(description: "Observation closure being called")
		let newName = ["John"]
		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValues: [([String]?, [String]?)] = [(nil, fixtureArray), (fixtureArray, newName), (newName, nil)]

		let cancellable = publisher.sink { actualValues in
			for (expected, actual) in zip(expectedValues, actualValues) {
				XCTAssertEqual(expected.0, actual.0)
				XCTAssertEqual(expected.1, actual.1)
			}

			expect.fulfill()
		}

		Defaults[key] = fixtureArray
		Defaults[key] = newName
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<[String]>("observeArrayKey", default: fixtureArray)
		let expect = expectation(description: "Observation closure being called")
		let newName = "John"

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, fixtureArray)
			XCTAssertEqual(change.newValue, [fixtureArray[0], newName])
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key][1] = newName

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<[String]?>("observeArrayOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertEqual(change.newValue!, fixtureArray)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureArray

		waitForExpectations(timeout: 10)
	}
}
