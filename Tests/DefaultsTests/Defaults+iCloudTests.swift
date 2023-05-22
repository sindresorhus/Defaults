@testable import Defaults
import SwiftUI
import XCTest

final class MockStorage: Defaults.KeyValueStore {
	private var pairs: [String: Any] = [:]

	func object<T>(forKey aKey: String) -> T? {
		pairs[aKey] as? T
	}

	func object(forKey aKey: String) -> Any? {
		pairs[aKey]
	}

	func set(_ anObject: Any?, forKey aKey: String) {
		pairs[aKey] = anObject
	}

	func removeObject(forKey aKey: String) {
		pairs.removeValue(forKey: aKey)
	}

	func removeAll() {
		pairs.removeAll()
	}

	func synchronize() -> Bool {
		NotificationCenter.default.post(Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, userInfo: [NSUbiquitousKeyValueStoreChangedKeysKey: Array(pairs.keys)]))
		return true
	}
}

private let mockStorage = MockStorage()

@available(iOS 15, tvOS 15, watchOS 8, *)
final class DefaultsICloudTests: XCTestCase {
	override class func setUp() {
		Defaults.iCloud.debug = true
		Defaults.iCloud.syncOnChange = true
		Defaults.iCloud.default = Defaults.iCloud(remoteStorage: mockStorage)
	}

	override func setUp() {
		super.setUp()
		Defaults.iCloud.removeAll()
		mockStorage.removeAll()
		Defaults.removeAll()
	}

	override func tearDown() {
		super.tearDown()
		Defaults.iCloud.removeAll()
		mockStorage.removeAll()
		Defaults.removeAll()
	}

	private func updateMockStorage<T>(key: String, value: T, _ date: Date? = nil) {
		mockStorage.set(value, forKey: key)
		mockStorage.set(date ?? Date(), forKey: "__DEFAULTS__synchronizeTimestamp")
	}

	func testICloudInitialize() async {
		let name = Defaults.Key<String>("testICloudInitialize_name", default: "0", iCloud: true)
		let quality = Defaults.Key<Double>("testICloudInitialize_quality", default: 0.0, iCloud: true)
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
		_ = mockStorage.synchronize()
		XCTAssertEqual(Defaults[quality], 8.0)
		XCTAssertEqual(Defaults[name], "8")

		Defaults[name] = "9"
		Defaults[quality] = 9.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "9")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 9.0)

		Defaults[name] = "10"
		Defaults[quality] = 10.0
		await Defaults.iCloud.sync()
		mockStorage.set("11", forKey: name.name)
		mockStorage.set(11.0, forKey: quality.name)
		_ = mockStorage.synchronize()
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
			_ = mockStorage.synchronize()
			XCTAssertEqual(Defaults[name], name_expected[index])
			XCTAssertEqual(Defaults[quality], quality_expected[index])
		}

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
		await Defaults.iCloud.sync()

		Defaults.iCloud.remove(quality)
		Defaults[name] = "1"
		Defaults[quality] = 1.0
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "1")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 0.0)
	}

	func testSyncKeysFromLocal() async {
		let name = Defaults.Key<String>("testSyncKeysFromLocal_name", default: "0")
		let quality = Defaults.Key<Double>("testSyncKeysFromLocal_quality", default: 0.0)
		let name_expected = ["1", "2", "3", "4", "5", "6", "7"]
		let quality_expected = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

		for index in 0..<name_expected.count {
			Defaults[name] = name_expected[index]
			Defaults[quality] = quality_expected[index]
			Defaults.iCloud.syncKeys(name, quality, source: .local)
			XCTAssertEqual(mockStorage.object(forKey: name.name), name_expected[index])
			XCTAssertEqual(mockStorage.object(forKey: quality.name), quality_expected[index])
		}

		updateMockStorage(key: name.name, value: "8")
		updateMockStorage(key: quality.name, value: 8)
		Defaults.iCloud.syncKeys(name, quality, source: .remote)
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
			Defaults.iCloud.syncKeys(name, quality, source: .remote)
			XCTAssertEqual(Defaults[name], name_expected[index])
			XCTAssertEqual(Defaults[quality], quality_expected[index])
		}

		Defaults[name] = "8"
		Defaults[quality] = 8.0
		Defaults.iCloud.syncKeys(name, quality, source: .local)
		await Defaults.iCloud.sync()
		XCTAssertEqual(mockStorage.object(forKey: name.name), "8")
		XCTAssertEqual(mockStorage.object(forKey: quality.name), 8.0)

		Defaults[name] = nil
		Defaults[quality] = nil
		Defaults.iCloud.syncKeys(name, quality, source: .local)
		await Defaults.iCloud.sync()
		XCTAssertNil(mockStorage.object(forKey: name.name))
		XCTAssertNil(mockStorage.object(forKey: quality.name))
	}

	func testAddFromDetached() async {
		let name = Defaults.Key<String>("testInitAddFromDetached_name", default: "0")
		let task = Task.detached {
			Defaults.iCloud.add(name)
			Defaults.iCloud.syncKeys()
			await Defaults.iCloud.sync()
		}
		await task.value
		XCTAssertEqual(mockStorage.object(forKey: name.name), "0")
	}

	func testICloudInitializeFromDetached() async {
		let task = Task.detached {
			let name = Defaults.Key<String>("testICloudInitializeFromDetached_name", default: "0", iCloud: true)
			await Defaults.iCloud.sync()
			XCTAssertEqual(mockStorage.object(forKey: name.name), "0")
		}
		await task.value
	}
}
