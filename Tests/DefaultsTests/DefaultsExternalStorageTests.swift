import Foundation
import Testing
@testable import Defaults

private let suite_ = UserDefaults.standard

extension Defaults.Keys {
	static let largeData = Key<Data>("externalStorageTest_largeData", default: Data(), externalStorage: true)
	static let normalData = Key<Data>("externalStorageTest_normalData", default: Data())
	static let optionalData = Key<Data?>("externalStorageTest_optionalData", externalStorage: true)
}

@Suite(.serialized)
final class DefaultsExternalStorageTests {
	init() {
		Defaults.Keys.largeData.reset()
		Defaults.Keys.normalData.reset()
		Defaults.Keys.optionalData.reset()
	}

	deinit {
		Defaults.Keys.largeData.reset()
		Defaults.Keys.normalData.reset()
		Defaults.Keys.optionalData.reset()
	}

	@Test
	func testExternalStorageParameter() {
		#expect(Defaults.Keys.largeData.usesExternalStorage == true)
		#expect(Defaults.Keys.normalData.usesExternalStorage == false)
	}

	@Test
	func testExternalStorageWithLargeData() throws {
		let largeData = Data(repeating: 0xFF, count: 1_000_000) // 1MB of data
		let key = Defaults.Keys.largeData

		Defaults[key] = largeData

		// Verify the data is stored externally - UserDefaults should only contain a UUID string
		let storedInUserDefaults = suite_.object(forKey: key.name)
		#expect(storedInUserDefaults is String)

		// Verify we can retrieve the data
		let retrieved = Defaults[key]
		#expect(retrieved == largeData)
	}

	@Test
	func testExternalStorageRetrievalAfterSet() throws {
		let testData = Data(repeating: 0xAB, count: 100_000)
		let key = Defaults.Keys.largeData

		Defaults[key] = testData
		#expect(Defaults[key] == testData)

		// Retrieve again to test persistence
		let retrieved = Defaults[key]
		#expect(retrieved == testData)
	}

	@Test
	func testExternalStorageCleanupOnReset() throws {
		let key = Defaults.Keys.largeData
		let testData = Data(repeating: 0xCD, count: 50_000)

		Defaults[key] = testData
		#expect(Defaults[key] == testData)

		// Get the file ID before reset
		let fileID = suite_.string(forKey: key.name)
		#expect(fileID != nil)

		// Reset should clean up the external file
		key.reset()
		#expect(Defaults[key] == Data())

		// Verify the UUID reference is gone
		#expect(suite_.string(forKey: key.name) == nil)

		// Verify the file was actually deleted from disk
		if let fileID = fileID {
			let directory = try Defaults.ExternalStorage.directoryURL(for: key.name)
			let fileURL = directory.appendingPathComponent(fileID)
			#expect(!FileManager.default.fileExists(atPath: fileURL.path))
		}
	}

	@Test
	func testExternalStorageOptionalValue() throws {
		let key = Defaults.Keys.optionalData
		let testData = Data(repeating: 0xEF, count: 25_000)

		// Test setting a value
		Defaults[key] = testData
		#expect(Defaults[key] == testData)

		// Test setting to nil
		Defaults[key] = nil
		#expect(Defaults[key] == nil)

		// Verify no UUID reference remains
		#expect(suite_.string(forKey: key.name) == nil)
	}

	@Test
	func testExternalStorageOverwrite() throws {
		let key = Defaults.Keys.largeData
		let data1 = Data(repeating: 0x11, count: 50_000)
		let data2 = Data(repeating: 0x22, count: 60_000)

		// Set first value
		Defaults[key] = data1
		let fileID1 = suite_.string(forKey: key.name)
		#expect(Defaults[key] == data1)
		#expect(fileID1 != nil)

		// Overwrite with second value
		Defaults[key] = data2
		let fileID2 = suite_.string(forKey: key.name)
		#expect(Defaults[key] == data2)
		#expect(fileID2 != nil)

		// File IDs should be different (old file cleaned up, new file created)
		#expect(fileID1 != fileID2)
	}

	@Test
	func testExternalStorageOnlyWorksWithStandardSuite() throws {
		let customSuite = UserDefaults(suiteName: "com.test.custom")!
		let key = Defaults.Key<Data>("customSuiteTest", default: Data(), suite: customSuite, externalStorage: true)

		// External storage should be disabled for non-standard suites
		#expect(key.usesExternalStorage == false)
	}

	@Test
	func testExternalStorageNilCleanup() throws {
		let key = Defaults.Keys.optionalData
		let testData = Data(repeating: 0xAA, count: 10_000)

		// Set a value
		Defaults[key] = testData
		let fileID = suite_.string(forKey: key.name)
		#expect(fileID != nil)
		#expect(Defaults[key] == testData)

		// Set to nil should clean up the file
		Defaults[key] = nil
		#expect(Defaults[key] == nil)
		#expect(suite_.string(forKey: key.name) == nil)

		// Verify the file was deleted (Bug #2 fix verification)
		if let fileID = fileID {
			let directory = try Defaults.ExternalStorage.directoryURL(for: key.name)
			let fileURL = directory.appendingPathComponent(fileID)
			#expect(!FileManager.default.fileExists(atPath: fileURL.path))
		}
	}

	@Test
	func testInvalidUUIDRejected() throws {
		let key = Defaults.Keys.largeData
		let testData = Data(repeating: 0xBB, count: 5_000)

		Defaults[key] = testData

		// Manually corrupt the UserDefaults to contain an invalid UUID
		suite_.set("../../../etc/passwd", forKey: key.name)

		// Should return default value and not crash (Bug #5 fix verification)
		let retrieved = Defaults[key]
		#expect(retrieved == Data())
	}

	@Test
	func testPathTraversalInKeyNamePrevented() throws {
		// This should fail at Key creation time since key names are validated
		// But if it somehow gets through, keyDirectory should reject it
		let maliciousKeyName = "../../etc/passwd"

		// This would fail the path traversal check in keyDirectory
		#expect(throws: Error.self) {
			try Defaults.ExternalStorage.keyDirectory(for: maliciousKeyName)
		}
	}

	@Test
	func testCodableTypesWithExternalStorage() throws {
		// Bug #21 fix verification: Codable types serialize to String, should now work
		struct TestUser: Codable, Defaults.Serializable {
			let name: String
			let age: Int
		}

		let userKey = Defaults.Key<TestUser>("testExternalUser", default: TestUser(name: "Default", age: 0), externalStorage: true)

		// Set a Codable value
		let user = TestUser(name: "Alice", age: 30)
		Defaults[userKey] = user

		// Verify it's stored externally (UUID in UserDefaults)
		let storedValue = suite_.object(forKey: userKey.name)
		#expect(storedValue is String)
		if let uuidString = storedValue as? String {
			#expect(UUID(uuidString: uuidString) != nil)
		}

		// Verify we can retrieve it
		let retrieved = Defaults[userKey]
		#expect(retrieved.name == "Alice")
		#expect(retrieved.age == 30)

		// Cleanup
		userKey.reset()
	}

	@Test
	func testURLWithExternalStorage() throws {
		// Bug #21 fix verification: URL serializes to String, should now work
		let urlKey = Defaults.Key<URL>("testExternalURL", default: URL(string: "https://example.com")!, externalStorage: true)

		let url = URL(string: "https://sindresorhus.com")!
		Defaults[urlKey] = url

		let retrieved = Defaults[urlKey]
		#expect(retrieved == url)

		// Cleanup
		urlKey.reset()
	}

	@Test
	func testUUIDWithExternalStorage() throws {
		// Bug #21 fix verification: UUID serializes to String, should now work
		let uuidKey = Defaults.Key<UUID>("testExternalUUID", default: UUID(), externalStorage: true)

		let uuid = UUID()
		Defaults[uuidKey] = uuid

		let retrieved = Defaults[uuidKey]
		#expect(retrieved == uuid)

		// Cleanup
		uuidKey.reset()
	}

	@Test
	func testRemoveAllCleansUpExternalFiles() throws {
		let key1 = Defaults.Key<Data>("removeAllTest1", default: Data(), externalStorage: true)
		let key2 = Defaults.Key<Data>("removeAllTest2", default: Data(), externalStorage: true)

		// Store data in both keys
		let data1 = Data(repeating: 0x11, count: 10_000)
		let data2 = Data(repeating: 0x22, count: 10_000)
		Defaults[key1] = data1
		Defaults[key2] = data2

		// Get file IDs before removeAll
		let fileID1 = suite_.string(forKey: key1.name)
		let fileID2 = suite_.string(forKey: key2.name)
		#expect(fileID1 != nil)
		#expect(fileID2 != nil)

		// Call removeAll
		suite_.removeAll()

		// Verify UserDefaults entries are gone
		#expect(suite_.string(forKey: key1.name) == nil)
		#expect(suite_.string(forKey: key2.name) == nil)

		// Verify files were deleted
		if let fileID1 = fileID1 {
			let directory1 = try Defaults.ExternalStorage.directoryURL(for: key1.name)
			let fileURL1 = directory1.appendingPathComponent(fileID1)
			#expect(!FileManager.default.fileExists(atPath: fileURL1.path))
		}

		if let fileID2 = fileID2 {
			let directory2 = try Defaults.ExternalStorage.directoryURL(for: key2.name)
			let fileURL2 = directory2.appendingPathComponent(fileID2)
			#expect(!FileManager.default.fileExists(atPath: fileURL2.path))
		}
	}

	@Test
	func testVeryLargeData() throws {
		// Test with 10MB of data
		let key = Defaults.Key<Data>("veryLargeDataTest", default: Data(), externalStorage: true)
		let largeData = Data(repeating: 0xAB, count: 10_000_000)

		Defaults[key] = largeData
		#expect(Defaults[key] == largeData)

		// Cleanup
		key.reset()
	}

	@Test
	func testRapidSuccessiveWrites() throws {
		// Test rapid writes to ensure no race conditions
		let key = Defaults.Key<Data>("rapidWriteTest", default: Data(), externalStorage: true)

		for iteration in 0..<10 {
			let data = Data(repeating: UInt8(iteration), count: 1000)
			Defaults[key] = data
			#expect(Defaults[key] == data)
		}

		// Cleanup
		key.reset()
	}

	@Test
	func testWritingSameValueMultipleTimes() throws {
		// Verify writing same value creates new file each time (for safety)
		let key = Defaults.Key<Data>("sameValueTest", default: Data(), externalStorage: true)
		let data = Data(repeating: 0xFF, count: 5000)

		Defaults[key] = data
		let fileID1 = suite_.string(forKey: key.name)

		Defaults[key] = data
		let fileID2 = suite_.string(forKey: key.name)

		// Should create new file each time (copy-on-write safety)
		#expect(fileID1 != fileID2)

		// Cleanup
		key.reset()
	}

	@Test
	func testCorruptedPlistHandling() throws {
		// Test that corrupted plist data returns default value
		let key = Defaults.Key<Data>("corruptedPlistTest", default: Data(repeating: 0x00, count: 100), externalStorage: true)

		// Save valid data first
		let validData = Data(repeating: 0xAA, count: 1000)
		Defaults[key] = validData

		// Get the file path and corrupt it
		if let fileID = suite_.string(forKey: key.name) {
			let directory = try Defaults.ExternalStorage.keyDirectory(for: key.name)
			let fileURL = directory.appendingPathComponent(fileID)

			// Write corrupted (non-plist) data
			try Data(repeating: 0xFF, count: 100).write(to: fileURL)

			// Should return default value when plist is corrupted
			let retrieved = Defaults[key]
			#expect(retrieved == Data(repeating: 0x00, count: 100))
		}

		// Cleanup
		key.reset()
	}

	@Test
	func testConcurrentAccess() async throws {
		// Test concurrent reads and writes
		let key = Defaults.Key<Data>("concurrentTest", default: Data(), externalStorage: true)

		await withTaskGroup(of: Void.self) { group in
			// Concurrent writes
			for iteration in 0..<5 {
				group.addTask {
					let data = Data(repeating: UInt8(iteration), count: 1000)
					Defaults[key] = data
				}
			}

			// Concurrent reads
			for _ in 0..<5 {
				group.addTask {
					_ = Defaults[key]
				}
			}
		}

		// Should still be readable after concurrent access
		_ = Defaults[key]

		// Cleanup
		key.reset()
	}

	@Test
	func testEmptyData() throws {
		// Test storing empty Data
		let key = Defaults.Key<Data>("emptyDataTest", default: Data([1, 2, 3]), externalStorage: true)

		Defaults[key] = Data()
		#expect(Defaults[key] == Data())

		// Cleanup
		key.reset()
	}

	@Test
	func testMaximumSizeData() throws {
		// Test near maximum size for property list (100MB)
		let key = Defaults.Key<Data>("maxSizeTest", default: Data(), externalStorage: true)
		let hugeData = Data(repeating: 0xCD, count: 100_000_000)

		Defaults[key] = hugeData
		#expect(Defaults[key] == hugeData)

		// Cleanup
		key.reset()
	}
}
