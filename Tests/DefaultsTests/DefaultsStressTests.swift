import Foundation
import Testing
@testable import Defaults

private let suite_ = UserDefaults(suiteName: UUID().uuidString)!

@Suite(.serialized)
final class DefaultsStressTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testConcurrentReadWrite() async {
		let key = Defaults.Key<Int>("concurrentTest", default: 0, suite: suite_)
		let iterations = 1000
		_ = (iterations * (iterations + 1)) / 2 // Sum of 1..1000 (unused for now)

		// Concurrent writes
		await withTaskGroup(of: Void.self) { group in
			for index in 1...iterations {
				group.addTask {
					Defaults[key] = index
				}
			}
		}

		// The last write wins, but we can't predict which one
		#expect(Defaults[key] > 0 && Defaults[key] <= iterations)
	}

	@Test
	func testConcurrentDifferentKeys() async {
		let keys = (0..<100).map { index in
			Defaults.Key<Int>("concurrent_\(index)", default: index, suite: suite_)
		}

		// Concurrent updates to different keys
		await withTaskGroup(of: Void.self) { group in
			for (index, key) in keys.enumerated() {
				group.addTask {
					// Each key gets updated to its index * 100
					Defaults[key] = index * 100
				}
			}
		}

		// Verify all updates succeeded
		for (index, key) in keys.enumerated() {
			#expect(Defaults[key] == index * 100)
		}
	}

	@Test
	func testRapidKeyUpdates() async {
		let key = Defaults.Key<Int>("rapidUpdate", default: 0, suite: suite_)
		let updateCount = 100

		// Rapid sequential updates
		for index in 1...updateCount {
			Defaults[key] = index
		}

		#expect(Defaults[key] == updateCount)

		// Rapid updates with small delays
		for index in 1...updateCount {
			Defaults[key] = index
			await Task.yield()
		}

		#expect(Defaults[key] == updateCount)
	}

	@Test
	func testLargeDataStorage() {
		// Test storing large strings
		let largeString = String(repeating: "A", count: 100_000) // 100KB string
		let key = Defaults.Key<String>("largeString", default: "", suite: suite_)

		Defaults[key] = largeString
		#expect(Defaults[key] == largeString)
		#expect(Defaults[key].count == 100_000)
	}

	@Test
	func testLargeArrayStorage() {
		// Test storing large arrays
		let largeArray = Array(0..<10_000) // 10,000 integers
		let key = Defaults.Key<[Int]>("largeArray", default: [], suite: suite_)

		Defaults[key] = largeArray
		#expect(Defaults[key] == largeArray)
		#expect(Defaults[key].count == 10_000)
	}

	@Test
	func testLargeDictionaryStorage() {
		// Test storing large dictionaries
		let largeDictionary = Dictionary(uniqueKeysWithValues: (0..<1000).map { ("key_\($0)", $0) })
		let key = Defaults.Key<[String: Int]>("largeDictionary", default: [:], suite: suite_)

		Defaults[key] = largeDictionary
		#expect(Defaults[key] == largeDictionary)
		#expect(Defaults[key].count == 1000)
	}

	@Test
	func testDeepNesting() {
		// Test deeply nested structures
		typealias NestedDict = [String: [String: [String: Int]]]

		let deepStructure: NestedDict = [
			"level1": [
				"level2": [
					"level3": 42
				]
			]
		]

		let key = Defaults.Key<NestedDict>("deepNesting", default: [:], suite: suite_)

		Defaults[key] = deepStructure
		#expect(Defaults[key]["level1"]?["level2"]?["level3"] == 42)
	}

	@Test
	func testManyKeys() {
		// Test handling many different keys
		let keyCount = 100
		let keys = (0..<keyCount).map { index in
			Defaults.Key<String>("manyKeys_\(index)", default: "default_\(index)", suite: suite_)
		}

		// Set values for all keys
		for (index, key) in keys.enumerated() {
			Defaults[key] = "value_\(index)"
		}

		// Verify all values
		for (index, key) in keys.enumerated() {
			#expect(Defaults[key] == "value_\(index)")
		}

		// Reset half of them
		for key in keys.prefix(keyCount / 2) {
			key.reset()
		}

		// Verify reset keys have default values
		for (index, key) in keys.prefix(keyCount / 2).enumerated() {
			#expect(Defaults[key] == "default_\(index)")
		}

		// Verify other half still have set values
		for index in (keyCount / 2)..<keyCount {
			#expect(Defaults[keys[index]] == "value_\(index)")
		}
	}

	@Test
	func testConcurrentObservations() async {
		let key = Defaults.Key<Int>("observationStress", default: 0, suite: suite_)
		let observationCount = _DefaultsAtomic(value: 0)
		var observations: [any Defaults.Observation] = []

		// Create multiple observers
		for _ in 0..<10 {
			let observation = Defaults.observe(key, options: []) { _ in
				observationCount.modify { $0 += 1 }
			}
			observations.append(observation)
		}

		// Make updates
		for index in 1...10 {
			Defaults[key] = index
			await Task.yield()
		}

		// Give time for observations to fire
		try? await Task.sleep(for: .milliseconds(100))

		// Each of 10 observers should see 10 updates
		#expect(observationCount.wrappedValue == 100)

		// Clean up
		for observation in observations {
			observation.invalidate()
		}
	}

	@Test
	func testMemoryPressure() async {
		// Test behavior under memory pressure by creating and destroying many keys
		for iteration in 0..<10 {
			autoreleasepool {
				let keys = (0..<100).map { index in
					Defaults.Key<Data>("memoryTest_\(iteration)_\(index)",
						default: Data(repeating: 0, count: 1000),
						suite: suite_)
				}

				// Set large data for each key
				for key in keys {
					Defaults[key] = Data(repeating: 0xFF, count: 10_000)
				}

				// Force cleanup
				Defaults.removeAll(suite: suite_)
			}

			await Task.yield()
		}

		// If we get here without crashing, the test passes
		#expect(Bool(true))
	}

	@Test
	func testEdgeCaseEmptyValues() {
		// Test empty string
		let stringKey = Defaults.Key<String>("emptyString", default: "default", suite: suite_)
		Defaults[stringKey] = ""
		#expect(Defaults[stringKey].isEmpty)
		#expect(Defaults[stringKey].isEmpty)

		// Test empty array
		let arrayKey = Defaults.Key<[Int]>("emptyArray", default: [1, 2, 3], suite: suite_)
		Defaults[arrayKey] = []
		#expect(Defaults[arrayKey].isEmpty)
		#expect(Defaults[arrayKey].isEmpty)

		// Test empty dictionary
		let dictKey = Defaults.Key<[String: Int]>("emptyDict", default: ["a": 1], suite: suite_)
		Defaults[dictKey] = [:]
		#expect(Defaults[dictKey].isEmpty)
		#expect(Defaults[dictKey].isEmpty)

		// Test empty set
		let setKey = Defaults.Key<Set<String>>("emptySet", default: ["a", "b"], suite: suite_)
		Defaults[setKey] = []
		#expect(Defaults[setKey] == Set<String>())
		#expect(Defaults[setKey].isEmpty)
	}

	@Test
	func testUnicodeAndSpecialCharacters() {
		let key = Defaults.Key<String>("unicodeTest", default: "", suite: suite_)

		// Test various Unicode characters
		let testStrings = [
			"Hello 世界 🌍",
			"Emoji: 😀😃😄😁😆",
			"Arabic: مرحبا بالعالم",
			"Hebrew: שלום עולם",
			"Math: ∑∏∫∞",
			"Symbols: ™®©℗",
			"Zero-width: \u{200B}test\u{200C}string\u{200D}",
			"Control: \n\r\t",
			String(repeating: "🦄", count: 1000) // 1000 emoji
		]

		for testString in testStrings {
			Defaults[key] = testString
			#expect(Defaults[key] == testString)
		}
	}

	@Test
	func testNumericEdgeCases() {
		// Test integer limits
		let intKey = Defaults.Key<Int>("intLimits", default: 0, suite: suite_)
		Defaults[intKey] = Int.max
		#expect(Defaults[intKey] == Int.max)
		Defaults[intKey] = Int.min
		#expect(Defaults[intKey] == Int.min)

		// Test double special values
		let doubleKey = Defaults.Key<Double>("doubleLimits", default: 0.0, suite: suite_)
		Defaults[doubleKey] = .infinity
		#expect(Defaults[doubleKey] == .infinity)
		Defaults[doubleKey] = -.infinity
		#expect(Defaults[doubleKey] == -.infinity)
		Defaults[doubleKey] = .nan
		#expect(Defaults[doubleKey].isNaN)

		// Test very small and very large numbers
		Defaults[doubleKey] = .leastNormalMagnitude
		#expect(Defaults[doubleKey] == .leastNormalMagnitude)
		Defaults[doubleKey] = .greatestFiniteMagnitude
		#expect(Defaults[doubleKey] == .greatestFiniteMagnitude)
	}

	@Test
	func testRapidResetCycle() async {
		let key = Defaults.Key<Int>("rapidReset", default: 42, suite: suite_)

		// Rapidly set and reset
		for index in 0..<100 {
			Defaults[key] = index * 100
			#expect(Defaults[key] == index * 100)
			key.reset()
			#expect(Defaults[key] == 42)
		}

		// Concurrent set and reset
		await withTaskGroup(of: Void.self) { group in
			for index in 0..<50 {
				group.addTask {
					Defaults[key] = index
				}
				group.addTask {
					key.reset()
				}
			}
		}

		// Value should be either the default or one of the set values
		let finalValue = Defaults[key]
		#expect(finalValue == 42 || (finalValue >= 0 && finalValue < 50))
	}

	@Test
	func testSuiteInterference() {
		// Test that different suites don't interfere - use unique suite names to prevent conflicts
		let suite1 = UserDefaults(suiteName: "stress_suite1_\(UUID().uuidString)")!
		let suite2 = UserDefaults(suiteName: "stress_suite2_\(UUID().uuidString)")!
		defer {
			suite1.removeAll()
			suite2.removeAll()
		}

		let key1 = Defaults.Key<String>("suite1_key", default: "default1", suite: suite1)
		let key2 = Defaults.Key<String>("suite2_key", default: "default2", suite: suite2)

		// Set different values
		Defaults[key1] = "value1"
		Defaults[key2] = "value2"

		// Verify isolation
		#expect(Defaults[key1] == "value1")
		#expect(Defaults[key2] == "value2")

		// Reset one shouldn't affect the other
		key1.reset()
		#expect(Defaults[key1] == "default1")
		#expect(Defaults[key2] == "value2")
	}
}
