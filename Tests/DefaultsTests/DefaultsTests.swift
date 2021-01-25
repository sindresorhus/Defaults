import Foundation
import Combine
import XCTest
import Defaults

let fixtureURL = URL(string: "https://sindresorhus.com")!
let fixtureFileURL = URL(string: "file://~/icon.png")!
let fixtureURL2 = URL(string: "https://example.com")!

let fixtureDate = Date()

extension Defaults.Keys {
	static let key = Key<Bool>("key", default: false)
	static let url = Key<URL>("url", default: fixtureURL)
	static let file = Key<URL>("fileURL", default: fixtureFileURL)
	static let data = Key<Data>("data", default: Data([]))
	static let date = Key<Date>("date", default: fixtureDate)
}

final class DefaultsTests: XCTestCase {
	override func setUp() {
		super.setUp()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.removeAll()
	}

	func testKey() {
		let key = Defaults.Key<Bool>("independentKey", default: false)
		XCTAssertFalse(Defaults[key])
		Defaults[key] = true
		XCTAssertTrue(Defaults[key])
	}

	func testOptionalKey() {
		let key = Defaults.Key<Bool?>("independentOptionalKey")
		let url = Defaults.Key<URL?>("independentOptionalURLKey")
		XCTAssertNil(Defaults[key])
		XCTAssertNil(Defaults[url])
		Defaults[key] = true
		Defaults[url] = fixtureURL
		XCTAssertTrue(Defaults[key]!)
		XCTAssertEqual(Defaults[url], fixtureURL)
		Defaults[key] = nil
		Defaults[url] = nil
		XCTAssertNil(Defaults[key])
		XCTAssertNil(Defaults[url])
		Defaults[key] = false
		Defaults[url] = fixtureURL2
		XCTAssertFalse(Defaults[key]!)
		XCTAssertEqual(Defaults[url], fixtureURL2)
	}

	func testKeyRegistersDefault() {
		let keyName = "registersDefault"
		XCTAssertFalse(UserDefaults.standard.bool(forKey: keyName))
		_ = Defaults.Key<Bool>(keyName, default: true)
		XCTAssertTrue(UserDefaults.standard.bool(forKey: keyName))

		// Test that it works with multiple keys with `Defaults`.
		let keyName2 = "registersDefault2"
		_ = Defaults.Key<String>(keyName2, default: keyName2)
		XCTAssertEqual(UserDefaults.standard.string(forKey: keyName2), keyName2)
	}

	func testKeyWithUserDefaultSubscript() {
		let key = Defaults.Key<Bool>("keyWithUserDeaultSubscript", default: false)
		XCTAssertFalse(UserDefaults.standard[key])
		UserDefaults.standard[key] = true
		XCTAssertTrue(UserDefaults.standard[key])
	}

	func testKeys() {
		XCTAssertFalse(Defaults[.key])
		Defaults[.key] = true
		XCTAssertTrue(Defaults[.key])
	}

	func testUrlType() {
		XCTAssertEqual(Defaults[.url], fixtureURL)
		let newUrl = URL(string: "https://twitter.com")!
		Defaults[.url] = newUrl
		XCTAssertEqual(Defaults[.url], newUrl)
	}

	func testDataType() {
		XCTAssertEqual(Defaults[.data], Data([]))
		let newData = Data([0xFF])
		Defaults[.data] = newData
		XCTAssertEqual(Defaults[.data], newData)
	}

	func testDateType() {
		XCTAssertEqual(Defaults[.date], fixtureDate)
		let newDate = Date()
		Defaults[.date] = newDate
		XCTAssertEqual(Defaults[.date], newDate)
	}

	func testFileURLType() {
		XCTAssertEqual(Defaults[.file], fixtureFileURL)
	}

	func testRemoveAll() {
		let key = Defaults.Key<Bool>("removeAll", default: false)
		let key2 = Defaults.Key<Bool>("removeAll2", default: false)
		Defaults[key] = true
		Defaults[key2] = true
		XCTAssertTrue(Defaults[key])
		XCTAssertTrue(Defaults[key2])
		Defaults.removeAll()
		XCTAssertFalse(Defaults[key])
		XCTAssertFalse(Defaults[key2])
	}

	func testCustomSuite() {
		let customSuite = UserDefaults(suiteName: "com.sindresorhus.customSuite")!
		let key = Defaults.Key<Bool>("customSuite", default: false, suite: customSuite)
		XCTAssertFalse(customSuite[key])
		XCTAssertFalse(Defaults[key])
		Defaults[key] = true
		XCTAssertTrue(customSuite[key])
		XCTAssertTrue(Defaults[key])
		Defaults.removeAll(suite: customSuite)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveKeyCombine() {
		let key = Defaults.Key<Bool>("observeKey", default: false)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(2)

		let cancellable = publisher.sink { tuples in
			for (index, expected) in [(false, true), (true, false)].enumerated() {
				XCTAssertEqual(expected.0, tuples[index].0)
				XCTAssertEqual(expected.1, tuples[index].1)
			}

			expect.fulfill()
		}

		Defaults[key] = true
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveOptionalKeyCombine() {
		let key = Defaults.Key<Bool?>("observeOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key, options: [])
			.map { ($0.oldValue, $0.newValue) }
			.collect(3)

		let expectedValues: [(Bool?, Bool?)] = [(nil, true), (true, false), (false, nil)]

		let cancellable = publisher.sink { actualValues in
			for (expected, actual) in zip(expectedValues, actualValues) {
				XCTAssertEqual(expected.0, actual.0)
				XCTAssertEqual(expected.1, actual.1)
			}

			expect.fulfill()
		}

		Defaults[key] = true
		Defaults[key] = false
		Defaults.reset(key)
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveMultipleKeysCombine() {
		let key1 = Defaults.Key<String>("observeKey1", default: "x")
		let key2 = Defaults.Key<Bool>("observeKey2", default: true)
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults.publisher(keys: key1, key2, options: []).collect(2)

		let cancellable = publisher.sink { _ in
			expect.fulfill()
		}

		Defaults[key1] = "y"
		Defaults[key2] = false
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObserveMultipleOptionalKeysCombine() {
		let key1 = Defaults.Key<String?>("observeOptionalKey1")
		let key2 = Defaults.Key<Bool?>("observeOptionalKey2")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults.publisher(keys: key1, key2, options: []).collect(2)

		let cancellable = publisher.sink { _ in
			expect.fulfill()
		}

		Defaults[key1] = "x"
		Defaults[key2] = false
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testReceiveValueBeforeSubscriptionCombine() {
		let key = Defaults.Key<String>("receiveValueBeforeSubscription", default: "hello")
		let expect = expectation(description: "Observation closure being called")

		let publisher = Defaults
			.publisher(key)
			.map(\.newValue)
			.eraseToAnyPublisher()
			.collect(2)

		let cancellable = publisher.sink { values in
			XCTAssertEqual(["hello", "world"], values)
			expect.fulfill()
		}

		Defaults[key] = "world"
		cancellable.cancel()
		waitForExpectations(timeout: 10)
	}

	func testObserveKey() {
		let key = Defaults.Key<Bool>("observeKey", default: false)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertFalse(change.oldValue)
			XCTAssertTrue(change.newValue)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	func testObserveOptionalKey() {
		let key = Defaults.Key<Bool?>("observeOptionalKey")
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertNil(change.oldValue)
			XCTAssertTrue(change.newValue!)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	func testObserveMultipleKeys() {
		let key1 = Defaults.Key<String>("observeKey1", default: "x")
		let key2 = Defaults.Key<Bool>("observeKey2", default: true)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		var counter = 0
		observation = Defaults.observe(keys: key1, key2, options: []) {
			counter += 1
			if counter == 2 {
				expect.fulfill()
			} else if counter > 2 {
				XCTFail()
			}
		}

		Defaults[key1] = "y"
		Defaults[key2] = false
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObserveKeyURL() {
		let key = Defaults.Key<URL>("observeKeyURL", default: fixtureURL)
		let expect = expectation(description: "Observation closure being called")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { change in
			XCTAssertEqual(change.oldValue, fixtureURL)
			XCTAssertEqual(change.newValue, fixtureURL2)
			observation.invalidate()
			expect.fulfill()
		}

		Defaults[key] = fixtureURL2

		waitForExpectations(timeout: 10)
	}

	func testObservePreventPropagation() {
		let key1 = Defaults.Key<Bool?>("preventPropagation0", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var observation: Defaults.Observation!
		var wasInside = false
		observation = Defaults.observe(key1, options: []) { _ in
			XCTAssertFalse(wasInside)
			wasInside = true
			Defaults.withoutPropagation {
				Defaults[key1] = true
			}
			expect.fulfill()
		}

		Defaults[key1] = false
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	func testObservePreventPropagationMultipleKeys() {
		let key1 = Defaults.Key<Bool?>("preventPropagation1", default: nil)
		let key2 = Defaults.Key<Bool?>("preventPropagation2", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var observation: Defaults.Observation!
		var wasInside = false
		observation = Defaults.observe(keys: key1, key2, options: []) {
			XCTAssertFalse(wasInside)
			wasInside = true
			Defaults.withoutPropagation {
				Defaults[key1] = true
			}
			expect.fulfill()
		}

		Defaults[key1] = false
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	// This checks if the callback is still being called if the value is changed on a second thread while the initial thread is doing some long running task.
	func testObservePreventPropagationMultipleThreads() {
		let key1 = Defaults.Key<Int?>("preventPropagation3", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var observation: Defaults.Observation!
		observation = Defaults.observe(key1, options: []) { _ in
			Defaults.withoutPropagation {
				Defaults[key1]! += 1
			}
			print("--- Main Thread: \(Thread.isMainThread)")
			if !Thread.isMainThread {
				XCTAssert(Defaults[key1]! == 4)
				expect.fulfill()
			} else {
				usleep(100_000)
				print("--- Release: \(Thread.isMainThread)")
			}
		}
		DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
			Defaults[key1]! += 1
		}
		Defaults[key1] = 1
		observation.invalidate()

		waitForExpectations(timeout: 10)
	}

	// Check if propagation prevention works across multiple observations.
	func testObservePreventPropagationMultipleObservations() {
		let key1 = Defaults.Key<Bool?>("preventPropagation4", default: nil)
		let key2 = Defaults.Key<Bool?>("preventPropagation5", default: nil)
		let expect = expectation(description: "No infinite recursion")

		let observation1 = Defaults.observe(key2, options: []) { _ in
			XCTFail()
		}

		let observation2 = Defaults.observe(keys: key1, key2, options: []) {
			Defaults.withoutPropagation {
				Defaults[key2] = true
			}
			expect.fulfill()
		}

		Defaults[key1] = false
		observation1.invalidate()
		observation2.invalidate()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObservePreventPropagationCombine() {
		let key1 = Defaults.Key<Bool?>("preventPropagation6", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var wasInside = false
		let cancellable = Defaults.publisher(key1, options: []).sink { _ in
			XCTAssertFalse(wasInside)
			wasInside = true
			Defaults.withoutPropagation {
				Defaults[key1] = true
			}
			expect.fulfill()
		}

		Defaults[key1] = false
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObservePreventPropagationMultipleKeysCombine() {
		let key1 = Defaults.Key<Bool?>("preventPropagation7", default: nil)
		let key2 = Defaults.Key<Bool?>("preventPropagation8", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var wasInside = false
		let cancellable = Defaults.publisher(keys: key1, key2, options: []).sink { _ in
			XCTAssertFalse(wasInside)
			wasInside = true
			Defaults.withoutPropagation {
				Defaults[key1] = true
			}
			expect.fulfill()
		}

		Defaults[key2] = false
		cancellable.cancel()

		waitForExpectations(timeout: 10)
	}

	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, iOSApplicationExtension 13.0, macOSApplicationExtension 10.15, tvOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
	func testObservePreventPropagationModifiersCombine() {
		let key1 = Defaults.Key<Bool?>("preventPropagation9", default: nil)
		let expect = expectation(description: "No infinite recursion")

		var wasInside = false
		var cancellable: AnyCancellable!
		cancellable = Defaults.publisher(key1, options: [])
			.receive(on: DispatchQueue.main)
			.delay(for: 0.5, scheduler: DispatchQueue.global())
			.sink { _ in
				XCTAssertFalse(wasInside)
				wasInside = true
				Defaults.withoutPropagation {
					Defaults[key1] = true
				}
				expect.fulfill()
				cancellable.cancel()
			}

		Defaults[key1] = false

		waitForExpectations(timeout: 10)
	}

	func testResetKey() {
		let defaultFixture1 = "foo1"
		let defaultFixture2 = 0
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let key1 = Defaults.Key<String>("key1", default: defaultFixture1)
		let key2 = Defaults.Key<Int>("key2", default: defaultFixture2)
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults.reset(key1)
		XCTAssertEqual(Defaults[key1], defaultFixture1)
		XCTAssertEqual(Defaults[key2], newFixture2)
	}

	func testResetMultipleKeys() {
		let defaultFxiture1 = "foo1"
		let defaultFixture2 = 0
		let defaultFixture3 = "foo3"
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let newFixture3 = "bar3"
		let key1 = Defaults.Key<String>("akey1", default: defaultFxiture1)
		let key2 = Defaults.Key<Int>("akey2", default: defaultFixture2)
		let key3 = Defaults.Key<String>("akey3", default: defaultFixture3)
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults[key3] = newFixture3
		Defaults.reset(key1, key2)
		XCTAssertEqual(Defaults[key1], defaultFxiture1)
		XCTAssertEqual(Defaults[key2], defaultFixture2)
		XCTAssertEqual(Defaults[key3], newFixture3)
	}

	func testResetMultipleOptionalKeys() {
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let newFixture3 = "bar3"
		let key1 = Defaults.Key<String?>("aoptionalKey1")
		let key2 = Defaults.Key<Int?>("aoptionalKey2")
		let key3 = Defaults.Key<String?>("aoptionalKey3")
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults[key3] = newFixture3
		Defaults.reset(key1, key2)
		XCTAssertNil(Defaults[key1])
		XCTAssertNil(Defaults[key2])
		XCTAssertEqual(Defaults[key3], newFixture3)
	}

	func testObserveWithLifetimeTie() {
		let key = Defaults.Key<Bool>("lifetimeTie", default: false)
		let expect = expectation(description: "Observation closure being called")

		weak var observation: Defaults.Observation!
		observation = Defaults.observe(key, options: []) { _ in
			observation.invalidate()
			expect.fulfill()
		}
			.tieToLifetime(of: self)

		Defaults[key] = true

		waitForExpectations(timeout: 10)
	}

	func testObserveWithLifetimeTieManualBreak() {
		let key = Defaults.Key<Bool>("lifetimeTieManualBreak", default: false)

		weak var observation: Defaults.Observation? = Defaults.observe(key, options: []) { _ in }.tieToLifetime(of: self)
		observation!.removeLifetimeTie()

		for index in 1...10 {
			if observation == nil {
				break
			}

			sleep(1)

			if index == 10 {
				XCTFail()
			}
		}
	}
}
