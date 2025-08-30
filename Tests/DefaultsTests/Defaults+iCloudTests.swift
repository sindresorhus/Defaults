import SwiftUI
import Testing
@testable import Defaults

private final class MockStorage: DefaultsKeyValueStore {
	private var pairs: [String: Any] = [:]
	private let queue = DispatchQueue(label: "a")

	func data<T>(forKey aKey: String) -> T? {
		queue.sync {
			guard
				let values = pairs[aKey] as? [Any],
				let data = values[safe: 1] as? T
			else {
				return nil
			}

			return data
		}
	}

	func object<T>(forKey aKey: String) -> T? {
		queue.sync {
			pairs[aKey] as? T
		}
	}

	func object(forKey aKey: String) -> Any? {
		queue.sync {
			pairs[aKey]
		}
	}

	func set(_ anObject: Any?, forKey aKey: String) {
		queue.sync {
			pairs[aKey] = anObject
		}
	}

	func removeObject(forKey aKey: String) {
		_ = queue.sync {
			pairs.removeValue(forKey: aKey)
		}
	}

	func removeAll() {
		queue.sync {
			pairs.removeAll()
		}
	}

	@discardableResult
	func synchronize() -> Bool {
		let pairs = queue.sync { Array(self.pairs.keys) }
		NotificationCenter.default.post(Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: pairs]))
		return true
	}
}

private let mockStorage = MockStorage()

@Suite(.serialized)
final class DefaultsICloudTests {
	private let suite = createSuite()

	init() {
		Defaults.iCloud.isDebug = true
		Defaults.iCloud.syncOnChange = true
		Defaults.iCloud.synchronizer = iCloudSynchronizer(remoteStorage: mockStorage)
	}

	deinit {
		mockStorage.removeAll()
		Defaults.iCloud.removeAll()
		Defaults.removeAll(suite: suite)
	}

	private func updateMockStorage(key: String, value: some Any, _ date: Date? = nil) {
		mockStorage.set([date ?? Date(), value], forKey: key)
	}

	@Test
	func testICloudInitialize() async {
		let name = Defaults.Key<String>("testICloudInitialize_name", default: "0", suite: suite, iCloud: true)
		let quality = Defaults.Key<Double>("testICloudInitialize_quality", default: 0.0, suite: suite, iCloud: true)

		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == nil)
		#expect(mockStorage.data(forKey: quality.name) == nil)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			await Defaults.iCloud.waitForSyncCompletion()
			#expect(mockStorage.data(forKey: name.name) == name_expected[index])
			#expect(mockStorage.data(forKey: quality.name) == quality_expected[index])
		}

		updateMockStorage(key: quality.name, value: 8.0)
		updateMockStorage(key: name.name, value: "8")
		mockStorage.synchronize()
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[quality] == 8.0)
		#expect(Defaults[name] == "8")

		Defaults[name] = "9"
		Defaults[quality] = 9.0
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "9")
		#expect(mockStorage.data(forKey: quality.name) == 9.0)

		updateMockStorage(key: quality.name, value: 10)
		updateMockStorage(key: name.name, value: "10")
		mockStorage.synchronize()
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[quality] == 10.0)
		#expect(Defaults[name] == "10")
	}

	@Test
	func testDidChangeExternallyNotification() async {
		updateMockStorage(key: "testDidChangeExternallyNotification_name", value: "0")
		updateMockStorage(key: "testDidChangeExternallyNotification_quality", value: 0.0)
		let name = Defaults.Key<String?>("testDidChangeExternallyNotification_name", suite: suite, iCloud: true)
		let quality = Defaults.Key<Double?>("testDidChangeExternallyNotification_quality", suite: suite, iCloud: true)
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[name] == "0")
		#expect(Defaults[quality] == 0.0)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			updateMockStorage(key: name.name, value: name_expected[index])
			updateMockStorage(key: quality.name, value: quality_expected[index])
			mockStorage.synchronize()
		}
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[name] == "7")
		#expect(Defaults[quality] == 7.0)

		Defaults[name] = "8"
		Defaults[quality] = 8.0
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "8")
		#expect(mockStorage.data(forKey: quality.name) == 8.0)

		Defaults[name] = nil
		Defaults[quality] = nil
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == nil)
		#expect(mockStorage.data(forKey: quality.name) == nil)
	}

	@Test
	func testICloudInitializeSyncLast() async {
		let name = Defaults.Key<String>("testICloudInitializeSyncLast_name", default: "0", suite: suite, iCloud: true)
		let quality = Defaults.Key<Double>("testICloudInitializeSyncLast_quality", default: 0.0, suite: suite, iCloud: true)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			#expect(Defaults[name] == name_expected[index])
			#expect(Defaults[quality] == quality_expected[index])
		}

		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "7")
		#expect(mockStorage.data(forKey: quality.name) == 7.0)
	}

	@Test
	func testRemoveKey() async {
		let name = Defaults.Key<String>("testRemoveKey_name", default: "0", suite: suite, iCloud: true)
		let quality = Defaults.Key<Double>("testRemoveKey_quality", default: 0.0, suite: suite, iCloud: true)
		Defaults[name] = "1"
		Defaults[quality] = 1.0
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "1")
		#expect(mockStorage.data(forKey: quality.name) == 1.0)

		Defaults.iCloud.remove(quality)
		Defaults[name] = "2"
		Defaults[quality] = 1.0
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "2")
		#expect(mockStorage.data(forKey: quality.name) == 1.0)
	}

	@Test
	func testSyncKeysFromLocal() async {
		let name = Defaults.Key<String>("testSyncKeysFromLocal_name", default: "0", suite: suite)
		let quality = Defaults.Key<Double>("testSyncKeysFromLocal_quality", default: 0.0, suite: suite)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
			await Defaults.iCloud.waitForSyncCompletion()
			#expect(mockStorage.data(forKey: name.name) == name_expected[index])
			#expect(mockStorage.data(forKey: quality.name) == quality_expected[index])
		}

		updateMockStorage(key: name.name, value: "8")
		updateMockStorage(key: quality.name, value: 8)
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .remote)
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[quality] == 8.0)
		#expect(Defaults[name] == "8")
	}

	@Test
	func testSyncKeysFromRemote() async {
		let name = Defaults.Key<String?>("testSyncKeysFromRemote_name", suite: suite)
		let quality = Defaults.Key<Double?>("testSyncKeysFromRemote_quality", suite: suite)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			updateMockStorage(key: name.name, value: name_expected[index])
			updateMockStorage(key: quality.name, value: quality_expected[index])
			Defaults.iCloud.syncWithoutWaiting(name, quality, source: .remote)
			await Defaults.iCloud.waitForSyncCompletion()
			#expect(Defaults[name] == name_expected[index])
			#expect(Defaults[quality] == quality_expected[index])
		}

		Defaults[name] = "8"
		Defaults[quality] = 8.0
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "8")
		#expect(mockStorage.data(forKey: quality.name) == 8.0)

		Defaults[name] = nil
		Defaults[quality] = nil
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.object(forKey: name.name) == nil)
		#expect(mockStorage.object(forKey: quality.name) == nil)
	}

	@Test
	func testAbortion() async {
		let name = Defaults.Key<String>("testAbortSingleKey_name", default: "0", iCloud: true) // swiftlint:disable:this discouraged_optional_boolean
		let quantity = Defaults.Key<Int>("testAbortSingleKey_quantity", default: 0, iCloud: true) // swiftlint:disable:this discouraged_optional_boolean
		Defaults[quantity] = 1
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: quantity.name) == 1)
		updateMockStorage(key: quantity.name, value: 2)
		Defaults.iCloud.syncWithoutWaiting()
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[name] == "0")
		#expect(Defaults[quantity] == 2)
	}


	@Test
	func testSyncLatestSource() async {
		let name = Defaults.Key<String>("testSyncLatestSource_name", default: "0", iCloud: true) // swiftlint:disable:this discouraged_optional_boolean
		let quantity = Defaults.Key<Int>("testSyncLatestSource_quantity", default: 0, iCloud: true) // swiftlint:disable:this discouraged_optional_boolean
		// Create a timestamp in both the local and remote data sources
		Defaults[name] = "1"
		Defaults[quantity] = 1
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "1")
		#expect(mockStorage.data(forKey: quantity.name) == 1)
		// Update remote storage
		updateMockStorage(key: name.name, value: "2")
		updateMockStorage(key: quantity.name, value: 2)
		Defaults.iCloud.syncWithoutWaiting()
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(Defaults[name] == "2")
		#expect(Defaults[quantity] == 2)
	}

	@Test
	func testAddFromDetached() async {
		let name = Defaults.Key<String?>("testInitAddFromDetached_name", suite: suite) // swiftlint:disable:this discouraged_optional_boolean
		let quantity = Defaults.Key<Bool?>("testInitAddFromDetached_quantity", suite: suite) // swiftlint:disable:this discouraged_optional_boolean
		await Task.detached {
			Defaults.iCloud.add(name, quantity)
			Defaults[name] = "0"
			Defaults[quantity] = true
			Defaults.iCloud.syncWithoutWaiting()
			await Defaults.iCloud.waitForSyncCompletion()
		}.value
		#expect(mockStorage.data(forKey: name.name) == "0")
		Defaults[name] = "1"
		await Defaults.iCloud.waitForSyncCompletion()
		#expect(mockStorage.data(forKey: name.name) == "1")
	}

	@Test
	func testICloudInitializeFromDetached() async {
		await Task.detached {
			let name = Defaults.Key<String>("testICloudInitializeFromDetached_name", default: "0", suite: self.suite, iCloud: true)

			await Defaults.iCloud.waitForSyncCompletion()
			#expect(mockStorage.data(forKey: name.name) == nil)
		}.value
	}
}
