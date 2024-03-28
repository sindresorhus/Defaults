import OSLog
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Combine
import Foundation
#if os(watchOS)
import WatchKit
#endif

extension Defaults {
	/**
	Synchronize values across devices using iCloud.

	To synchronize a key with iCloud, set `iCloud: true` on the ``Defaults/Key``. That's it! ✨

	```swift
	import Defaults

	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false, iCloud: true)
	}

	// …

	// This change will now be synced to other devices.
	Defaults[.isUnicornMode] = true
	```

	- Important: You need to enable the `iCloud` capability in the “Signing and Capabilities” tab in Xcode and then enable “Key-value storage” in the iCloud services.

	## Notes

	- If there is a conflict, it will use the latest change.
	- Max 1024 keys and a total of 1 MB storage.
	- It uses [`NSUbiquitousKeyValueStore`](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore) internally.

	## Dynamically Toggle Syncing

	You can also toggle the syncing behavior dynamically using the ``Defaults/iCloud/add(_:)-5gffb`` and ``Defaults/iCloud/remove(_:)-1b8w5`` methods.

	```swift
	import Defaults

	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	// …

	if shouldSync {
		Defaults.iCloud.add(.isUnicornMode)
	}
	```
	*/
	public enum iCloud {
		/**
		The singleton for Defaults's iCloudSynchronizer.
		*/
		static var synchronizer = iCloudSynchronizer(remoteStorage: NSUbiquitousKeyValueStore.default)

		/**
		The synced keys.
		*/
		public static var keys: Set<Defaults.Keys> { synchronizer.keys }

		// Note: Can be made public if someone shows a real use-case for it.
		/**
		Enable this if you want the key to be synced right away when it's changed.
		*/
		static var syncOnChange = true

		/**
		Log debug info about the syncing.

		It will include details such as the key being synced, its corresponding value, and the status of the synchronization.
		*/
		public static var isDebug = false

		/**
		Add the keys to be automatically synced.
		*/
		public static func add(_ keys: Defaults.Keys...) {
			synchronizer.add(keys)
		}

		/**
		Add the keys to be automatically synced.
		*/
		public static func add(_ keys: [Defaults.Keys]) {
			synchronizer.add(keys)
		}

		/**
		Remove the keys that are set to be automatically synced.
		*/
		public static func remove(_ keys: Defaults.Keys...) {
			synchronizer.remove(keys)
		}

		/**
		Remove the keys that are set to be automatically synced.
		*/
		public static func remove(_ keys: [Defaults.Keys]) {
			synchronizer.remove(keys)
		}

		/**
		Remove all keys that are set to be automatically synced.
		*/
		public static func removeAll() {
			synchronizer.removeAll()
		}

		/**
		Waits for the completion of synchronization.

		You generally don't need this as synchronization is automatic, but in some cases it could be useful to not continue until all values are synchronized to the cloud.

		```swift
		import Defaults

		extension Defaults.Keys {
			static let isUnicornMode = Key<Bool>("isUnicornMode", default: false, iCloud: true)
		}

		// …

		Task {
			Defaults[.isUnicornMode] = true

			print(Defaults[.isUnicornMode])
			//=> true

			await Defaults.iCloud.waitForSyncCompletion()

			// The value is now synchronized to the cloud too.
		}
		```
		*/
		public static func waitForSyncCompletion() async {
			await synchronizer.sync()
		}

		// Only make these public if there is an actual need.
		// https://github.com/sindresorhus/Defaults/pull/136#discussion_r1544546756

		/**
		Create synchronization tasks for all the keys that have been added to the ``Defaults/iCloud``.
		*/
		static func syncWithoutWaiting() {
			synchronizer.syncWithoutWaiting()
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source, which can be either a remote server or a local cache.

		- Parameter keys: The keys that should be synced.
		- Parameter source: Sync keys from which data source(remote or local)

		- Note: `source` should be specified if `key` has not been added to ``Defaults/iCloud``.
		*/
		static func syncWithoutWaiting(_ keys: Defaults.Keys..., source: DataSource? = nil) {
			synchronizer.syncWithoutWaiting(keys, source)
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source, which can be either a remote server or a local cache.

		- Parameter keys: The keys that should be synced.
		- Parameter source: Sync keys from which data source(remote or local)

		- Note: `source` should be specified if `key` has not been added to ``Defaults/iCloud``.
		*/
		static func syncWithoutWaiting(_ keys: [Defaults.Keys], source: DataSource? = nil) {
			synchronizer.syncWithoutWaiting(keys, source)
		}
	}
}

extension Defaults.iCloud {
	/**
	Represent different data sources available for synchronization.
	*/
	public enum DataSource {
		/**
		Using `key.suite` as data source.
		*/
		case local

		/**
		Using `NSUbiquitousKeyValueStore` as data source.
		*/
		case remote
	}
}

private enum SyncStatus {
	case idle
	case syncing
	case completed
}

/**
Manages `Defaults.Keys` between the locale and remote storage.

Depending on the storage, `Defaults.Keys` will be represented in different forms due to storage limitations of the remote storage. The remote storage imposes a limitation of 1024 keys. Therefore, we combine the recorded timestamp and data into a single key. Unlike remote storage, local storage does not have this limitation. Therefore, we can create a separate key (with `defaultsSyncKey` suffix) for the timestamp record.
*/
final class iCloudSynchronizer {
	init(remoteStorage: DefaultsKeyValueStore) {
		self.remoteStorage = remoteStorage
		registerNotifications()
		remoteStorage.synchronize()
	}

	deinit {
		removeAll()
	}

	@TaskLocal static var timestamp: Date?

	private var cancellables = Set<AnyCancellable>()

	/**
	Key for recording the synchronization between `NSUbiquitousKeyValueStore` and `UserDefaults`.
	*/
	private let defaultsSyncKey = "__DEFAULTS__synchronizeTimestamp"

	/**
	A remote key value storage.
	*/
	private let remoteStorage: DefaultsKeyValueStore

	/**
	A FIFO queue used to serialize synchronization on keys.
	*/
	private let backgroundQueue = TaskQueue(priority: .utility)

	/**
	A thread-safe `keys` that manage the keys to be synced.
	*/
	@Atomic(value: []) private(set) var keys: Set<Defaults.Keys>

	/**
	A thread-safe synchronization status monitor for `keys`.
	*/
	@Atomic(value: []) private var remoteSyncingKeys: Set<Defaults.Keys>

	// TODO: Replace it with async stream when Swift supports custom executors.
	private lazy var localKeysMonitor: Defaults.CompositeUserDefaultsAnyKeyObservation = .init { [weak self] observable in
		guard
			let self,
			let suite = observable.suite,
			let key = keys.first(where: { $0.name == observable.key && $0.suite == suite }),
			// Prevent triggering local observation when syncing from remote.
			!remoteSyncingKeys.contains(key)
		else {
			return
		}

		enqueue {
			self.recordTimestamp(forKey: key, timestamp: Self.timestamp, source: .local)
			await self.syncKey(key, source: .local)
		}
	}

	/**
	Add new key and start to observe its changes.
	*/
	func add(_ keys: [Defaults.Keys]) {
		self.keys.formUnion(keys)
		syncWithoutWaiting(keys)
		for key in keys {
			localKeysMonitor.addObserver(key)
		}
	}

	/**
	Remove key and stop the observation.
	*/
	func remove(_ keys: [Defaults.Keys]) {
		self.keys.subtract(keys)
		for key in keys {
			localKeysMonitor.removeObserver(key)
		}
	}

	/**
	Remove all sync keys.
	*/
	func removeAll() {
		localKeysMonitor.invalidate()
		_keys.modify { $0.removeAll() }
		_remoteSyncingKeys.modify { $0.removeAll() }
	}

	/**
	Explicitly synchronizes in-memory keys and values with those stored on disk.
	*/
	func synchronize() {
		remoteStorage.synchronize()
	}

	/**
	Synchronize the specified `keys` from the given `source` without waiting.

	- Parameter keys: If the keys parameter is an empty array, the method will use the keys that were added to `Defaults.iCloud`.
	- Parameter source: Sync keys from which data source (remote or local).
	*/
	func syncWithoutWaiting(_ keys: [Defaults.Keys] = [], _ source: Defaults.iCloud.DataSource? = nil) {
		let keys = keys.isEmpty ? Array(self.keys) : keys

		for key in keys {
			let latest = source ?? latestDataSource(forKey: key)
			enqueue {
				await self.syncKey(key, source: latest)
			}
		}
	}

	/**
	Wait until all synchronization tasks are complete.
	*/
	func sync() async {
		await backgroundQueue.flush()
	}

	/**
	Enqueue the synchronization task into `backgroundQueue` with the current timestamp.
	*/
	private func enqueue(_ task: @escaping TaskQueue.AsyncTask) {
		backgroundQueue.async {
			await Self.$timestamp.withValue(Date()) {
				await task()
			}
		}
	}

	/**
	Create synchronization tasks for the specified `key` from the given source.

	- Parameter key: The key to synchronize.
	- Parameter source: Sync key from which data source (remote or local).
	*/
	private func syncKey(_ key: Defaults.Keys, source: Defaults.iCloud.DataSource) async {
		Self.logKeySyncStatus(key, source: source, syncStatus: .idle)

		switch source {
		case .remote:
			await syncFromRemote(forKey: key)
		case .local:
			syncFromLocal(forKey: key)
		}

		Self.logKeySyncStatus(key, source: source, syncStatus: .completed)
	}

	/**
	Only update the value if it can be retrieved from the remote storage.
	*/
	private func syncFromRemote(forKey key: Defaults.Keys) async {
		_remoteSyncingKeys.modify { $0.insert(key) }

		await withCheckedContinuation { continuation in
			guard
				let object = remoteStorage.object(forKey: key.name) as? [Any],
				let date = Self.timestamp,
				let value = object[safe: 1]
			else {
				continuation.resume()
				return
			}

			Task { @MainActor in
				Self.logKeySyncStatus(key, source: .remote, syncStatus: .syncing, value: value)
				key.suite.set(value, forKey: key.name)
				key.suite.set(date, forKey: "\(key.name)\(defaultsSyncKey)")
				continuation.resume()
			}
		}

		_remoteSyncingKeys.modify { $0.remove(key) }
	}

	/**
	Retrieve a value from local storage, and if it does not exist, remove it from the remote storage.
	*/
	private func syncFromLocal(forKey key: Defaults.Keys) {
		guard
			let value = key.suite.object(forKey: key.name),
			let date = Self.timestamp
		else {
			Self.logKeySyncStatus(key, source: .local, syncStatus: .syncing, value: nil)
			remoteStorage.removeObject(forKey: key.name)
			syncRemoteStorageOnChange()
			return
		}

		Self.logKeySyncStatus(key, source: .local, syncStatus: .syncing, value: value)
		remoteStorage.set([date, value], forKey: key.name)
		syncRemoteStorageOnChange()
	}

	/**
	Explicitly synchronizes in-memory keys and values when a value is changed.
	*/
	private func syncRemoteStorageOnChange() {
		if Defaults.iCloud.syncOnChange {
			synchronize()
		}
	}

	/**
	Retrieve the timestamp associated with the specified key from the source provider.

	The timestamp storage format varies across different source providers due to storage limitations.
	*/
	private func timestamp(forKey key: Defaults.Keys, source: Defaults.iCloud.DataSource) -> Date? {
		switch source {
		case .remote:
			guard
				let values = remoteStorage.object(forKey: key.name) as? [Any],
				let timestamp = values[safe: 0] as? Date
			else {
				return nil
			}

			return timestamp
		case .local:
			guard
				let timestamp = key.suite.object(forKey: "\(key.name)\(defaultsSyncKey)") as? Date
			else {
				return nil
			}

			return timestamp
		}
	}

	/**
	Mark the current timestamp to the given storage.
	*/
	func recordTimestamp(forKey key: Defaults.Keys, timestamp: Date?, source: Defaults.iCloud.DataSource) {
		switch source {
		case .remote:
			guard
				let values = remoteStorage.object(forKey: key.name) as? [Any],
				let data = values[safe: 1],
				let timestamp
			else {
				return
			}

			remoteStorage.set([timestamp, data], forKey: key.name)
		case .local:
			guard let timestamp else {
				return
			}
			key.suite.set(timestamp, forKey: "\(key.name)\(defaultsSyncKey)")
		}
	}

	/**
	Determine which data source has the latest data available by comparing the timestamps of the local and remote sources.
	*/
	private func latestDataSource(forKey key: Defaults.Keys) -> Defaults.iCloud.DataSource {
		// If the remote timestamp does not exist, use the local timestamp as the latest data source.
		guard let remoteTimestamp = timestamp(forKey: key, source: .remote) else {
			return .local
		}
		guard let localTimestamp = timestamp(forKey: key, source: .local) else {
			return .remote
		}

		return localTimestamp > remoteTimestamp ? .local : .remote
	}
}

// Notification related functions.
extension iCloudSynchronizer {
	private func registerNotifications() {
		// TODO: Replace it with async stream when Swift supports custom executors.
		NotificationCenter.default
			.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
			.sink { [weak self] notification in
				guard let self else {
					return
				}

				didChangeExternally(notification: notification)
			}
			.store(in: &cancellables)

		#if canImport(UIKit)
		#if os(watchOS)
		let notificationName = WKExtension.applicationWillEnterForegroundNotification
		#else
		let notificationName = UIScene.willEnterForegroundNotification
		#endif

		// TODO: Replace it with async stream when Swift supports custom executors.
		NotificationCenter.default
			.publisher(for: notificationName)
			.sink { [weak self] notification in
				guard let self else {
					return
				}

				willEnterForeground(notification: notification)
			}
			.store(in: &cancellables)
		#endif
	}

	private func willEnterForeground(notification: Notification) {
		remoteStorage.synchronize()
	}

	private func didChangeExternally(notification: Notification) {
		guard notification.name == NSUbiquitousKeyValueStore.didChangeExternallyNotification else {
			return
		}

		guard
			let userInfo = notification.userInfo,
			let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
			// If `@TaskLocal timestamp` is not nil, it indicates that this notification is triggered by `syncRemoteStorageOnChange`, and therefore, we can skip updating the local storage.
			Self.timestamp._defaults_isNil
		else {
			return
		}

		for key in keys where changedKeys.contains(key.name) {
			guard let remoteTimestamp = self.timestamp(forKey: key, source: .remote) else {
				continue
			}
			if
				let localTimestamp = self.timestamp(forKey: key, source: .local),
				localTimestamp >= remoteTimestamp
			{
				continue
			}

			self.enqueue {
				await self.syncKey(key, source: .remote)
			}
		}
	}
}

// Logging related functions.
extension iCloudSynchronizer {
	private static let logger = Logger(OSLog.default)

	private static func logKeySyncStatus(
		_ key: Defaults.Keys,
		source: Defaults.iCloud.DataSource,
		syncStatus: SyncStatus,
		value: Any? = nil
	) {
		guard Defaults.iCloud.isDebug else {
			return
		}

		let destination = switch source {
		case .local:
			"from local"
		case .remote:
			"from remote"
		}

		let status: String
		var valueDescription = " "
		switch syncStatus {
		case .idle:
			status = "Try synchronizing"
		case .syncing:
			status = "Synchronizing"
			valueDescription = " with value \(value ?? "nil") "
		case .completed:
			status = "Complete synchronization"
		}

		let message = "\(status) key '\(key.name)'\(valueDescription)\(destination)"
		log(message)
	}

	private static func log(_ message: String) {
		guard Defaults.iCloud.isDebug else {
			return
		}

		logger.debug("[Defaults.iCloud] \(message)")
	}
}
