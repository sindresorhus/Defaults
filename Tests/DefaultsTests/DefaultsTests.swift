// swiftlint:disable discouraged_optional_boolean
import Foundation
import Combine
import Testing
@testable import Defaults

func createSuite() -> UserDefaults {
	UserDefaults(suiteName: UUID().uuidString)!
}

private let suite_ = createSuite()

let fixtureURL = URL(string: "https://sindresorhus.com")!
let fixtureFileURL = URL(string: "file://~/icon.png")!
let fixtureURL2 = URL(string: "https://example.com")!
let fixtureDate = Date()

extension Defaults.Keys {
	static let key = Key<Bool>("key", default: false, suite: suite_)
	static let url = Key<URL>("url", default: fixtureURL, suite: suite_)
	static let file = Key<URL>("fileURL", default: fixtureFileURL, suite: suite_)
	static let data = Key<Data>("data", default: Data([]), suite: suite_)
	static let date = Key<Date>("date", default: fixtureDate, suite: suite_)
	static let uuid = Key<UUID?>("uuid", suite: suite_)
	static let defaultDynamicDate = Key<Date>("defaultDynamicOptionalDate", suite: suite_) { Date(timeIntervalSince1970: 0) }
	static let defaultDynamicOptionalDate = Key<Date?>("defaultDynamicOptionalDate", suite: suite_) { Date(timeIntervalSince1970: 1) }
}

@Suite(.serialized)
final class DefaultsTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testKey() {
		let key = Defaults.Key<Bool>("independentKey", default: false, suite: suite_)
		#expect(!Defaults[key])
		Defaults[key] = true
		#expect(Defaults[key])
	}

	@Test
	func testValidKeyName() {
		let validKey = Defaults.Key<Bool>("test", default: false, suite: suite_)
		let containsDotKey = Defaults.Key<Bool>("test.a", default: false, suite: suite_)
		let startsWithAtKey = Defaults.Key<Bool>("@test", default: false, suite: suite_)
		#expect(Defaults.isValidKeyPath(name: validKey.name))
		#expect(!Defaults.isValidKeyPath(name: containsDotKey.name))
		#expect(!Defaults.isValidKeyPath(name: startsWithAtKey.name))
	}

	@Test
	func testOptionalKey() {
		let key = Defaults.Key<Bool?>("independentOptionalKey", suite: suite_)
		let url = Defaults.Key<URL?>("independentOptionalURLKey", suite: suite_)
		#expect(Defaults[key] == nil)
		#expect(Defaults[url] == nil)
		Defaults[key] = true
		Defaults[url] = fixtureURL
		#expect(Defaults[key] == true)
		#expect(Defaults[url] == fixtureURL)
		Defaults[key] = nil
		Defaults[url] = nil
		#expect(Defaults[key] == nil)
		#expect(Defaults[url] == nil)
		Defaults[key] = false
		Defaults[url] = fixtureURL2
		#expect(Defaults[key] == false)
		#expect(Defaults[url] == fixtureURL2)
	}

	@Test
	func testInitializeDynamicDateKey() {
		_ = Defaults.Key<Date>("independentInitializeDynamicDateKey", suite: suite_) {
			Issue.record("Init dynamic key should not trigger getter")
			return Date()
		}
		_ = Defaults.Key<Date?>("independentInitializeDynamicOptionalDateKey", suite: suite_) {
			Issue.record("Init dynamic optional key should not trigger getter")
			return Date()
		}
	}

	@Test
	func testKeyRegistersDefault() {
		let keyName = "registersDefault"
		#expect(!suite_.bool(forKey: keyName))
		_ = Defaults.Key<Bool>(keyName, default: true, suite: suite_)
		#expect(suite_.bool(forKey: keyName))

		let keyName2 = "registersDefault2"
		_ = Defaults.Key<String>(keyName2, default: keyName2, suite: suite_)
		#expect(suite_.string(forKey: keyName2) == keyName2)
	}

	@Test
	func testKeyWithUserDefaultSubscript() {
		let key = Defaults.Key<Bool>("keyWithUserDeaultSubscript", default: false, suite: suite_)
		#expect(!suite_[key])
		suite_[key] = true
		#expect(suite_[key])
	}

	@Test
	func testKeys() {
		#expect(!Defaults[.key])
		Defaults[.key] = true
		#expect(Defaults[.key])
	}

	@Test
	func testUrlType() {
		#expect(Defaults[.url] == fixtureURL)
		let newUrl = URL(string: "https://twitter.com")!
		Defaults[.url] = newUrl
		#expect(Defaults[.url] == newUrl)
	}

	@Test
	func testDataType() {
		#expect(Defaults[.data] == Data([]))
		let newData = Data([0xFF])
		Defaults[.data] = newData
		#expect(Defaults[.data] == newData)
	}

	@Test
	func testDateType() {
		#expect(Defaults[.date] == fixtureDate)
		let newDate = Date()
		Defaults[.date] = newDate
		#expect(Defaults[.date] == newDate)
	}

	@Test
	func testDynamicDateType() {
		#expect(Defaults[.defaultDynamicDate] == Date(timeIntervalSince1970: 0))
		let next = Date(timeIntervalSince1970: 1)
		Defaults[.defaultDynamicDate] = next
		#expect(Defaults[.defaultDynamicDate] == next)
		#expect(suite_.object(forKey: Defaults.Key<Date>.defaultDynamicDate.name) as! Date == next)
		Defaults.Key<Date>.defaultDynamicDate.reset()
		#expect(Defaults[.defaultDynamicDate] == Date(timeIntervalSince1970: 0))
	}

	@Test
	func testDynamicOptionalDateType() {
		#expect(Defaults[.defaultDynamicOptionalDate] == Date(timeIntervalSince1970: 1))
		let next = Date(timeIntervalSince1970: 2)
		Defaults[.defaultDynamicOptionalDate] = next
		#expect(Defaults[.defaultDynamicOptionalDate] == next)
		#expect(suite_.object(forKey: Defaults.Key<Date>.defaultDynamicOptionalDate.name) as! Date == next)
		Defaults[.defaultDynamicOptionalDate] = nil
		#expect(Defaults[.defaultDynamicOptionalDate] == Date(timeIntervalSince1970: 1))
		#expect(suite_.object(forKey: Defaults.Key<Date>.defaultDynamicOptionalDate.name) == nil)
	}

	@Test
	func testFileURLType() {
		#expect(Defaults[.file] == fixtureFileURL)
	}

	@Test
	func testUUIDType() {
		let fixture = UUID()
		Defaults[.uuid] = fixture
		#expect(Defaults[.uuid] == fixture)
	}

	@Test
	func testRemoveAll() {
		let key = Defaults.Key<Bool>("removeAll", default: false, suite: suite_)
		let key2 = Defaults.Key<Bool>("removeAll2", default: false, suite: suite_)
		Defaults[key] = true
		Defaults[key2] = true
		#expect(Defaults[key])
		#expect(Defaults[key2])
		Defaults.removeAll(suite: suite_)
		#expect(!Defaults[key])
		#expect(!Defaults[key2])
	}

	@Test
	func testCustomSuite() {
		let customSuite = UserDefaults(suiteName: "com.sindresorhus.customSuite")!
		let key = Defaults.Key<Bool>("customSuite", default: false, suite: customSuite)
		#expect(!customSuite[key])
		#expect(!Defaults[key])
		Defaults[key] = true
		#expect(customSuite[key])
		#expect(Defaults[key])
		Defaults.removeAll(suite: customSuite)
	}

	@Test
	func testIsDefaultValue() {
		let key = Defaults.Key<Bool>("isDefaultValue", default: false, suite: suite_)
		#expect(key.isDefaultValue)
		Defaults[key].toggle()
		#expect(!key.isDefaultValue)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveKeyCombine() async throws {
		let key = Defaults.Key<Bool>("observeKey", default: false, suite: suite_)
		var results: [(Bool, Bool)] = []

		try await confirmation(expectedCount: 2) { confirmation in
			let publisher = Defaults
				.publisher(key, options: [])
				.map { ($0.oldValue, $0.newValue) }
				.sink { value in
					results.append(value)
					confirmation()
				}

			await Task.yield()
			Defaults[key] = true
			Defaults.reset(key)

			try await Task.sleep(for: .milliseconds(100))
			publisher.cancel()
		}

		let expectedValues = [(false, true), (true, false)]

		// Manual comparison needed as tuple arrays don't conform to Equatable
		#expect(results.count == expectedValues.count)
		for (index, expected) in expectedValues.enumerated() {
			#expect(results[index].0 == expected.0)
			#expect(results[index].1 == expected.1)
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveOptionalKeyCombine() async throws {
		let key = Defaults.Key<Bool?>("observeOptionalKey", suite: suite_)
		var results: [(Bool?, Bool?)] = []

		try await confirmation(expectedCount: 3) { confirmation in
			let publisher = Defaults
				.publisher(key, options: [])
				.map { ($0.oldValue, $0.newValue) }
				.sink { value in
					results.append(value)
					confirmation()
				}

			await Task.yield()
			Defaults[key] = true
			Defaults[key] = false
			Defaults.reset(key)

			try await Task.sleep(for: .milliseconds(100))
			publisher.cancel()
		}

		let expectedValues: [(Bool?, Bool?)] = [(nil, true), (true, false), (false, nil)]

		// Manual comparison needed as tuple arrays don't conform to Equatable
		#expect(results.count == expectedValues.count)
		for (index, expected) in expectedValues.enumerated() {
			#expect(results[index].0 == expected.0)
			#expect(results[index].1 == expected.1)
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testDynamicOptionalDateTypeCombine() async throws {
		let first = Date(timeIntervalSince1970: 0)
		let second = Date(timeIntervalSince1970: 1)
		let third = Date(timeIntervalSince1970: 2)
		let key = Defaults.Key<Date?>("combineDynamicOptionalDateKey", suite: suite_) { first }
		var results: [(Date?, Date?)] = []

		try await confirmation(expectedCount: 3) { confirmation in
			let publisher = Defaults
				.publisher(key, options: [])
				.map { ($0.oldValue, $0.newValue) }
				.sink { value in
					results.append(value)
					confirmation()
				}

			await Task.yield()
			Defaults[key] = second
			Defaults[key] = third
			Defaults.reset(key)

			try await Task.sleep(for: .milliseconds(100))
			publisher.cancel()
		}

		let expectedValues: [(Date?, Date?)] = [(first, second), (second, third), (third, first)]

		// Manual comparison needed as tuple arrays don't conform to Equatable
		#expect(results.count == expectedValues.count)
		for (index, expected) in expectedValues.enumerated() {
			#expect(results[index].0 == expected.0)
			#expect(results[index].1 == expected.1)
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveMultipleKeysCombine() async throws {
		let key1 = Defaults.Key<String>("observeKey1", default: "x", suite: suite_)
		let key2 = Defaults.Key<Bool>("observeKey2", default: true, suite: suite_)
		var count = 0

		try await confirmation(expectedCount: 2) { confirmation in
			let publisher = Defaults.publisher(keys: key1, key2, options: [])
				.sink { _ in
					count += 1
					confirmation()
				}

			await Task.yield()
			Defaults[key1] = "y"
			Defaults[key2] = false

			try await Task.sleep(for: .milliseconds(100))
			publisher.cancel()
		}

		#expect(count == 2)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testObserveMultipleOptionalKeysCombine() async throws {
		let key1 = Defaults.Key<String?>("observeOptionalKey1", suite: suite_)
		let key2 = Defaults.Key<Bool?>("observeOptionalKey2", suite: suite_)
		var count = 0

		try await confirmation(expectedCount: 2) { confirmation in
			let publisher = Defaults.publisher(keys: key1, key2, options: [])
				.sink { _ in
					count += 1
					confirmation()
				}

			await Task.yield()
			Defaults[key1] = "x"
			Defaults[key2] = false

			try await Task.sleep(for: .milliseconds(100))
			publisher.cancel()
		}

		#expect(count == 2)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testReceiveValueBeforeSubscriptionCombine() async throws {
		let key = Defaults.Key<String>("receiveValueBeforeSubscription", default: "hello", suite: suite_)

		try await confirmation(expectedCount: 2) { confirmation in
			let publisher = Defaults
				.publisher(key)
				.map(\.newValue)
				.sink { _ in
					confirmation()
				}

			// Ensure we're subscribed before changing the value
			await Task.yield()

			// Change the value
			Defaults[key] = "world"

			// Keep the subscription alive
			try await Task.sleep(for: .milliseconds(100))

			publisher.cancel()
		}
	}

	@Test
	func testObservePreventPropagationCombine() async throws {
		let key1 = Defaults.Key<Bool?>("preventPropagation6", default: nil, suite: suite_)

		await confirmation { confirmation in
			var wasInside = false
			let cancellable = Defaults.publisher(key1, options: []).sink { _ in
				#expect(!wasInside)
				wasInside = true
				Defaults.withoutPropagation {
					Defaults[key1] = true
				}
				confirmation()
			}

			Defaults[key1] = false
			cancellable.cancel()
		}
	}

	@Test
	func testObservePreventPropagationMultipleKeysCombine() async throws {
		let key1 = Defaults.Key<Bool?>("preventPropagation7", default: nil, suite: suite_)
		let key2 = Defaults.Key<Bool?>("preventPropagation8", default: nil, suite: suite_)

		await confirmation { confirmation in
			var wasInside = false
			let cancellable = Defaults.publisher(keys: key1, key2, options: []).sink { _ in
				#expect(!wasInside)
				wasInside = true
				Defaults.withoutPropagation {
					Defaults[key1] = true
				}
				confirmation()
			}

			Defaults[key2] = false
			cancellable.cancel()
		}
	}

	@Test
	func testResetKey() {
		let defaultFixture1 = "foo1"
		let defaultFixture2 = 0
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let key1 = Defaults.Key<String>("key1", default: defaultFixture1, suite: suite_)
		let key2 = Defaults.Key<Int>("key2", default: defaultFixture2, suite: suite_)
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults.reset(key1)
		#expect(Defaults[key1] == defaultFixture1)
		#expect(Defaults[key2] == newFixture2)
	}

	@Test
	func testResetMultipleKeys() {
		let defaultFxiture1 = "foo1"
		let defaultFixture2 = 0
		let defaultFixture3 = "foo3"
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let newFixture3 = "bar3"
		let key1 = Defaults.Key<String>("akey1", default: defaultFxiture1, suite: suite_)
		let key2 = Defaults.Key<Int>("akey2", default: defaultFixture2, suite: suite_)
		let key3 = Defaults.Key<String>("akey3", default: defaultFixture3, suite: suite_)
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults[key3] = newFixture3
		Defaults.reset(key1, key2)
		#expect(Defaults[key1] == defaultFxiture1)
		#expect(Defaults[key2] == defaultFixture2)
		#expect(Defaults[key3] == newFixture3)
	}

	@Test
	func testResetMultipleOptionalKeys() {
		let newFixture1 = "bar1"
		let newFixture2 = 1
		let newFixture3 = "bar3"
		let key1 = Defaults.Key<String?>("aoptionalKey1", suite: suite_)
		let key2 = Defaults.Key<Int?>("aoptionalKey2", suite: suite_)
		let key3 = Defaults.Key<String?>("aoptionalKey3", suite: suite_)
		Defaults[key1] = newFixture1
		Defaults[key2] = newFixture2
		Defaults[key3] = newFixture3
		Defaults.reset(key1, key2)
		#expect(Defaults[key1] == nil)
		#expect(Defaults[key2] == nil)
		#expect(Defaults[key3] == newFixture3)
	}

	@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
	@Test
	func testImmediatelyFinishingPublisherCombine() async throws {
		let key = Defaults.Key<Bool>("observeKey", default: false, suite: suite_)

		let result: Void? = try await withThrowingTaskGroup(of: Void.self) { group in
			let publisher = Defaults
				.publisher(key, options: [.initial])
				.first()

			group.addTask {
				for try await _ in publisher.values {
					return
				}
			}

			return try await group.next()
		}

		#expect(result != nil)
	}

	@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
	@Test
	func testImmediatelyFinishingMultiplePublisherCombine() async throws {
		let key1 = Defaults.Key<Bool>("observeKey1", default: false, suite: suite_)
		let key2 = Defaults.Key<String>("observeKey2", default: "🦄", suite: suite_)

		let result: Void? = try await withThrowingTaskGroup(of: Void.self) { group in
			let publisher = Defaults
				.publisher(keys: [key1, key2], options: [.initial])
				.first()

			group.addTask {
				for try await _ in publisher.values {
					return
				}
			}

			return try await group.next()
		}

		#expect(result != nil)
	}

	@Test
	func testKeyEquatable() {
		// swiftlint:disable:next identical_operands
		#expect(Defaults.Key<Bool>("equatableKeyTest", default: false, suite: suite_) == Defaults.Key<Bool>("equatableKeyTest", default: false, suite: suite_))
	}

	@Test
	func testKeyHashable() {
		_ = Set([Defaults.Key<Bool>("hashableKeyTest", default: false, suite: suite_)])
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testUpdates() async {
		let key = Defaults.Key<Bool>("updatesKey", default: false, suite: suite_)

		async let waiter = Defaults.updates(key, initial: false).first { $0 }

		try? await Task.sleep(for: .seconds(0.1))

		Defaults[key] = true

		guard let result = await waiter else {
			Issue.record("Failed to get result")
			return
		}

		#expect(result)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testUpdatesMultipleKeys() async {
		let key1 = Defaults.Key<Bool>("updatesMultipleKey1", default: false, suite: suite_)
		let key2 = Defaults.Key<Bool>("updatesMultipleKey2", default: false, suite: suite_)
		let counter = Counter()

		async let waiter: Void = {
			for await _ in Defaults.updates([key1, key2], initial: false) {
				await counter.increment()

				if await counter.count == 2 {
					break
				}
			}
		}()

		try? await Task.sleep(for: .seconds(0.1))

		Defaults[key1] = true
		Defaults[key2] = true

		await waiter

		let count = await counter.count
		#expect(count == 2)
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	@Test
	func testUpdatesMultipleKeysVariadic() async {
		let key1 = Defaults.Key<Bool>("updatesMultipleKeyVariadic1", default: false, suite: suite_)
		let key2 = Defaults.Key<Bool>("updatesMultipleKeyVariadic2", default: false, suite: suite_)
		let counter = Counter()

		async let waiter: Void = {
			for await (_, _) in Defaults.updates(key1, key2, initial: false) {
				await counter.increment()

				if await counter.count == 2 {
					break
				}
			}
		}()

		try? await Task.sleep(for: .seconds(0.1))

		Defaults[key1] = true
		Defaults[key2] = true

		await waiter

		let count = await counter.count
		#expect(count == 2)
	}
}

actor Counter {
	private var _count = 0

	var count: Int { _count }

	func increment() {
		_count += 1
	}
}

// swiftlint:enable discouraged_optional_boolean
