@testable import Defaults
import SwiftUI
import XCTest

final class MockStorage: Defaults.KeyValueStore {
	private var pairs: [String: Any] = [:]
	private let queue = DispatchQueue(label: "a")

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
		let pairs = queue.sync {
			Array(self.pairs.keys)
		}
		NotificationCenter.default.post(Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: pairs]))
		return true
	}
}

private let mockStorage = MockStorage()

@available(iOS 15, tvOS 15, watchOS 8, *)
final class DefaultsICloudTests: XCTestCase {
	override class func setUp() {
		Defaults.iCloud.isDebug = true
		Defaults.iCloud.synchronizer = Defaults.iCloudSynchronizer(remoteStorage: mockStorage)
	}

	override func setUp() {
		super.setUp()
		mockStorage.removeAll()
		Defaults.iCloud.removeAll()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		mockStorage.removeAll()
		Defaults.iCloud.removeAll()
		Defaults.removeAll()
	}

	private func updateMockStorage<T>(key: String, value: T, _ date: Date? = nil) {
		mockStorage.set(value, forKey: key)
		mockStorage.set(date ?? Date(), forKey: "__DEFAULTS__synchronizeTimestamp")
	}

	func testICloudInitialize() async {
		let name = Defaults.Key<String>("testICloudInitialize_name", default: "0", iCloud: true)
		let quality = Defaults.Key<Double>("testICloudInitialize_quality", default: 0.0, iCloud: true)
		// Not sure why github action will not trigger a observation callback after initialization, cannot reproduce in local.
		Defaults.iCloud.syncWithoutWaiting()
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "0")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 0.0)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			await Defaults.iCloud.sync()
			XCTAssertEqual(mockStorage.object(forKey: name.name), name_expected[index])
			XCTAssertEqual(mockStorage.object(forKey: quality.name), quality_expected[index])
		}

		updateMockStorage(key: quality.name, value: 8.0)
		updateMockStorage(key: name.name, value: "8")
		mockStorage.synchronize()
		await Defaults.iCloud.sync()
		XCTAssertEqual(Defaults[quality], 8.0)
		XCTAssertEqual(Defaults[name], "8")

		Defaults[name] = "9"
		Defaults[quality] = 9.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "9")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 9.0)

		mockStorage.set("10", forKey: name.name)
		mockStorage.set(10.0, forKey: quality.name)
		mockStorage.synchronize()
		await Defaults.iCloud.sync()
		XCTAssertEqual(Defaults[quality], 10.0)
		XCTAssertEqual(Defaults[name], "10")
	}

	func testDidChangeExternallyNotification() async {
		let name = Defaults.Key<String?>("testDidChangeExternallyNotification_name", iCloud: true)
		let quality = Defaults.Key<Double?>("testDidChangeExternallyNotification_quality", iCloud: true)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			updateMockStorage(key: name.name, value: name_expected[index])
			updateMockStorage(key: quality.name, value: quality_expected[index])
			mockStorage.synchronize()
		}
		await Defaults.iCloud.sync()
		XCTAssertEqual(Defaults[name], "7")
		XCTAssertEqual(Defaults[quality], 7.0)

		Defaults[name] = "8"
		Defaults[quality] = 8.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "8")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 8.0)

		Defaults[name] = nil
		Defaults[quality] = nil
		await Defaults.iCloud.sync()
		XCTAssertNil(mockStorage.object(forKey: name.name))
		XCTAssertNil(mockStorage.object(forKey: quality.name))
	}

	func testICloudInitializeSyncLast() async {
		let name = Defaults.Key<String>("testICloudInitializeSyncLast_name", default: "0", iCloud: true)
		let quality = Defaults.Key<Double>("testICloudInitializeSyncLast_quality", default: 0.0, iCloud: true)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			XCTAssertEqual(Defaults[name], name_expected[index])
			XCTAssertEqual(Defaults[quality], quality_expected[index])
		}

		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "7")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 7.0)
	}

	func testRemoveKey() async {
		let name = Defaults.Key<String>("testRemoveKey_name", default: "0", iCloud: true)
		let quality = Defaults.Key<Double>("testRemoveKey_quality", default: 0.0, iCloud: true)
		Defaults[name] = "1"
		Defaults[quality] = 1.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "1")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 1.0)

		Defaults.iCloud.remove(quality)
		Defaults[name] = "2"
		Defaults[quality] = 1.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "2")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 1.0)
	}

	func testSyncKeysFromLocal() async {
		let name = Defaults.Key<String>("testSyncKeysFromLocal_name", default: "0")
		let quality = Defaults.Key<Double>("testSyncKeysFromLocal_quality", default: 0.0)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
			await Defaults.iCloud.sync()
			XCTAssertEqual(mockStorage.object(forKey: name.name), name_expected[index])
			XCTAssertEqual(mockStorage.object(forKey: quality.name), quality_expected[index])
		}

		updateMockStorage(key: name.name, value: "8")
		updateMockStorage(key: quality.name, value: 8)
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .remote)
		await Defaults.iCloud.sync()
		XCTAssertEqual(Defaults[quality], 8.0)
		XCTAssertEqual(Defaults[name], "8")
	}

	func testSyncKeysFromRemote() async {
		let name = Defaults.Key<String?>("testSyncKeysFromRemote_name")
		let quality = Defaults.Key<Double?>("testSyncKeysFromRemote_quality")
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			updateMockStorage(key: name.name, value: name_expected[index])
			updateMockStorage(key: quality.name, value: quality_expected[index])
			Defaults.iCloud.syncWithoutWaiting(name, quality, source: .remote)
			await Defaults.iCloud.sync()
			XCTAssertEqual(Defaults[name], name_expected[index])
			XCTAssertEqual(Defaults[quality], quality_expected[index])
		}

		Defaults[name] = "8"
		Defaults[quality] = 8.0
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "8")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 8.0)

		Defaults[name] = nil
		Defaults[quality] = nil
		Defaults.iCloud.syncWithoutWaiting(name, quality, source: .local)
		await Defaults.iCloud.sync()
		XCTAssertNil(mockStorage.object(forKey: name.name))
		XCTAssertNil(mockStorage.object(forKey: quality.name))
	}

	func testAddFromDetached() async {
		let name = Defaults.Key<String>("testInitAddFromDetached_name", default: "0")
		let task = Task.detached {
			Defaults.iCloud.add(name)
			Defaults.iCloud.syncWithoutWaiting()
			await Defaults.iCloud.sync()
		}
		await task.value
		XCTAssertEqual(mockStorage.object(forKey: name.name), "0")
		Defaults[name] = "1"
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "1")
	}

	func testICloudInitializeFromDetached() async {
		let task = Task.detached {
			let name = Defaults.Key<String>("testICloudInitializeFromDetached_name", default: "0", iCloud: true)
			// Not sure why github action will not trigger a observation callback after initialization, cannot reproduce in local.
			Defaults.iCloud.syncWithoutWaiting()
			await Defaults.iCloud.sync()
			XCTAssertEqual(mockStorage.object(forKey: name.name), "0")
		}
		await task.value
	}
}
