import Foundation
import Testing
@testable import Defaults

private let suite_ = UserDefaults(suiteName: UUID().uuidString)!

extension Defaults.Keys {
	fileprivate static let observationTest = Key<String>("observationTest", default: "initial", suite: suite_)
	fileprivate static let concurrencyTest = Key<Int>("concurrencyTest", default: 0, suite: suite_)
	fileprivate static let preventPropagationTest = Key<String>("preventPropagationTest", default: "initial", suite: suite_)
}

@Suite(.serialized)
final class DefaultsObservationAdvancedTests {
	init() {
		Defaults.removeAll(suite: suite_)
	}

	deinit {
		Defaults.removeAll(suite: suite_)
	}

	@Test
	func testObservationWithoutPropagation() async throws {
		var changeCount = 0
		var lastValue = ""

		try await confirmation(expectedCount: 2) { confirmation in
			let observation = Defaults.observe(.preventPropagationTest) { change in
				changeCount += 1
				lastValue = change.newValue

				// This change should not trigger another observation due to withoutPropagation
				Defaults.withoutPropagation {
					Defaults[.preventPropagationTest] = "from_observer"
				}

				confirmation()
			}

			// Wait for initial observation
			try await Task.sleep(for: .milliseconds(10))

			// Normal change should trigger observation
			Defaults[.preventPropagationTest] = "external_change"

			observation.invalidate()
		}

		#expect(changeCount == 2)
		#expect(lastValue == "external_change")

		// The value set within withoutPropagation should be applied but not observed
		#expect(Defaults[.preventPropagationTest] == "from_observer")
	}

	@Test
	func testMultipleObservationsOnSameKey() async throws {
		var observer1Count = 0
		var observer2Count = 0

		// We expect 4 total confirmations: 2 initial + 2 on change
		try await confirmation(expectedCount: 4) { confirmation in
			let observation1 = Defaults.observe(.observationTest) { _ in
				observer1Count += 1
				confirmation()
			}

			let observation2 = Defaults.observe(.observationTest) { _ in
				observer2Count += 1
				confirmation()
			}

			// Wait for initial observations
			try await Task.sleep(for: .milliseconds(10))

			// Both should get update notification
			Defaults[.observationTest] = "changed"

			observation1.invalidate()
			observation2.invalidate()
		}

		#expect(observer1Count == 2)
		#expect(observer2Count == 2)
	}

	@Test
	func testObservationInvalidation() async throws {
		var changeCount = 0

		await confirmation { confirmation in
			let observation = Defaults.observe(.observationTest, options: []) { _ in
				changeCount += 1
				confirmation()
			}

			// Change value
			Defaults[.observationTest] = "test1"

			// After confirmation, invalidate observation
			observation.invalidate()
		}

		#expect(changeCount == 1)

		// Further changes should not trigger observation
		Defaults[.observationTest] = "test2"

		// Wait a bit to ensure no observation fires
		try? await Task.sleep(for: .milliseconds(50))
		#expect(changeCount == 1) // Should still be 1
	}

	@Test
	func testLifetimeTiedObservation() async throws {
		var changeCount = 0
		var owner: NSObject? = NSObject()

		try await confirmation(expectedCount: 2) { confirmation in
			let observation = Defaults.observe(.observationTest) { _ in
				changeCount += 1
				confirmation()
			}
			.tieToLifetime(of: owner!)

			// Wait for initial observation
			try await Task.sleep(for: .milliseconds(10))

			// Change value
			Defaults[.observationTest] = "tied_test"

			_ = observation // Keep reference
		}

		#expect(changeCount == 2)

		// Release owner - observation should be invalidated
		owner = nil

		// Give time for cleanup
		try? await Task.sleep(for: .milliseconds(50))

		// Further changes should not trigger observation
		let countBefore = changeCount
		Defaults[.observationTest] = "after_owner_released"

		try? await Task.sleep(for: .milliseconds(50))
		#expect(changeCount == countBefore) // Should not have changed
	}

	@Test
	func testObservationLifetimeTieRemoval() async throws {
		var changeCount = 0
		let owner = NSObject()

		try await confirmation(expectedCount: 2) { confirmation in
			let observation = Defaults.observe(.observationTest) { _ in
				changeCount += 1
				confirmation()
			}
			.tieToLifetime(of: owner)

			// Wait for initial observation
			try await Task.sleep(for: .milliseconds(10))

			// Remove lifetime tie
			observation.removeLifetimeTie()

			// Change value - should still work since observation is not invalidated
			Defaults[.observationTest] = "after_tie_removal"

			// Explicitly invalidate at the end
			observation.invalidate()
		}

		#expect(changeCount == 2)

		// Now changes should not trigger observation
		let countBefore = changeCount
		Defaults[.observationTest] = "after_invalidation"

		try? await Task.sleep(for: .milliseconds(50))
		#expect(changeCount == countBefore)
	}

	@Test
	func testConcurrentObservation() async {
		let key = Defaults.Key<Int>("concurrentObservation", default: 0, suite: suite_)
		let observationCount = _DefaultsAtomic(value: 0)

		let observation = Defaults.observe(key) { _ in
			observationCount.modify { $0 += 1 }
		}

		// Perform concurrent updates
		await withTaskGroup(of: Void.self) { group in
			for index in 1...100 {
				group.addTask {
					Defaults[key] = index
				}
			}
		}

		// Wait for observations to complete
		try? await Task.sleep(for: .milliseconds(100))

		// Should have observed initial + many changes
		#expect(observationCount.wrappedValue > 100)

		observation.invalidate()
	}

	@Test
	func testAsyncUpdatesStream() async {
		let key = Defaults.Key<String>("asyncUpdates", default: "start", suite: suite_)
		var receivedValues: [String] = []

		let updateTask = Task {
			for await value in Defaults.updates(key) {
				receivedValues.append(value)
				if value == "update3" {
					break
				}
			}
		}

		// Initial value should be received
		try? await Task.sleep(for: .milliseconds(50))

		// Make some updates
		Defaults[key] = "update1"
		try? await Task.sleep(for: .milliseconds(25))

		Defaults[key] = "update2"
		try? await Task.sleep(for: .milliseconds(25))

		Defaults[key] = "update3"

		_ = await updateTask.result

		#expect(receivedValues.contains("start")) // Initial value
		#expect(receivedValues.contains("update1"))
		#expect(receivedValues.contains("update2"))
		#expect(receivedValues.contains("update3"))
	}

	@Test
	func testAsyncUpdatesStreamWithoutInitial() async {
		let key = Defaults.Key<String>("asyncUpdatesNoInitial", default: "start", suite: suite_)
		var receivedValues: [String] = []

		let updateTask = Task {
			for await value in Defaults.updates(key, initial: false) {
				receivedValues.append(value)
				if value == "update2" {
					break
				}
			}
		}

		// Give a moment for stream to be set up
		try? await Task.sleep(for: .milliseconds(50))

		// Make some updates
		Defaults[key] = "update1"
		try? await Task.sleep(for: .milliseconds(25))

		Defaults[key] = "update2"

		_ = await updateTask.result

		#expect(!receivedValues.contains("start")) // Should not include initial
		#expect(receivedValues.contains("update1"))
		#expect(receivedValues.contains("update2"))
	}

	@Test
	func testMultipleKeysUpdatesStream() async {
		let key1 = Defaults.Key<String>("multiKey1", default: "start1", suite: suite_)
		let key2 = Defaults.Key<Int>("multiKey2", default: 0, suite: suite_)
		var receivedUpdates: [(String, Int)] = []

		let updateTask = Task {
			for await (value1, value2) in Defaults.updates(key1, key2) {
				receivedUpdates.append((value1, value2))
				if receivedUpdates.count >= 3 { // initial + 2 updates
					break
				}
			}
		}

		// Give initial values time to be received
		try? await Task.sleep(for: .milliseconds(50))

		// Update first key
		Defaults[key1] = "changed1"
		try? await Task.sleep(for: .milliseconds(25))

		// Update second key
		Defaults[key2] = 42

		_ = await updateTask.result

		#expect(receivedUpdates.count >= 3)

		// Should start with initial values
		let initialUpdate = receivedUpdates[0]
		#expect(initialUpdate.0 == "start1")
		#expect(initialUpdate.1 == 0)
	}

	@Test
	func testArrayKeysUpdatesStream() async {
		let key1 = Defaults.Key<String>("arrayKey1", default: "start1", suite: suite_)
		let key2 = Defaults.Key<Int>("arrayKey2", default: 0, suite: suite_)
		var updateCount = 0

		let updateTask = Task {
			for await _ in Defaults.updates([key1, key2]) {
				updateCount += 1
				if updateCount >= 3 { // initial + 2 updates
					break
				}
			}
		}

		// Give initial notification time to be received
		try? await Task.sleep(for: .milliseconds(50))

		// Update keys
		Defaults[key1] = "changed1"
		try? await Task.sleep(for: .milliseconds(25))

		Defaults[key2] = 42

		_ = await updateTask.result

		#expect(updateCount >= 3)
	}

	@Test
	func testCompositeObservation() async {
		let key1 = Defaults.Key<String>("composite1", default: "start1", suite: suite_)
		let key2 = Defaults.Key<Int>("composite2", default: 0, suite: suite_)
		var updateCount = 0

		// Test basic composite observation functionality
		let observation = Defaults.observe(keys: key1, key2, options: []) {
			updateCount += 1
		}

		// Update first key
		Defaults[key1] = "changed"
		try? await Task.sleep(for: .milliseconds(50))

		// Update second key  
		Defaults[key2] = 42
		try? await Task.sleep(for: .milliseconds(50))

		// Should have observed at least the key changes
		#expect(updateCount >= 2, "Should have observed key changes")

		observation.invalidate()
	}
}
