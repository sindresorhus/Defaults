import OSLog
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Combine
import Foundation

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

	private var cancellables: Set<AnyCancellable> = []

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
			let key = self.keys.first(where: { $0.name == observable.key && $0.suite == suite }),
			// Prevent triggering local observation when syncing from remote.
			!self.remoteSyncingKeys.contains(key)
		else {
			return
		}

		self.enqueue {
			self.recordTimestamp(forKey: key, timestamp: Self.timestamp, source: .local)
			await self.syncKey(key, source: .local)
		}
	}

	/**
	Add new key and start to observe its changes.
	*/
	func add(_ keys: [Defaults.Keys]) {
		self.keys.formUnion(keys)
		self.syncWithoutWaiting(keys)
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
	func syncWithoutWaiting(_ keys: [Defaults.Keys] = [], _ source: Defaults.DataSource? = nil) {
		let keys = keys.isEmpty ? Array(self.keys) : keys

		for key in keys {
			let latest = source ?? latestDataSource(forKey: key)
			self.enqueue {
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
		self.backgroundQueue.async {
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
	private func syncKey(_ key: Defaults.Keys, source: Defaults.DataSource) async {
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
	private func timestamp(forKey key: Defaults.Keys, source: Defaults.DataSource) -> Date? {
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
	func recordTimestamp(forKey key: Defaults.Keys, timestamp: Date?, source: Defaults.DataSource) {
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
	private func latestDataSource(forKey key: Defaults.Keys) -> Defaults.DataSource {
		// If the remote timestamp does not exist, use the local timestamp as the latest data source.
		guard let remoteTimestamp = self.timestamp(forKey: key, source: .remote) else {
			return .local
		}
		guard let localTimestamp = self.timestamp(forKey: key, source: .local) else {
			return .remote
		}

		return localTimestamp > remoteTimestamp ? .local : .remote
	}
}

/**
`iCloudSynchronizer` notification related functions.
*/
extension iCloudSynchronizer {
	private func registerNotifications() {
		// TODO: Replace it with async stream when Swift supports custom executors.
		NotificationCenter.default
			.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
			.sink { [weak self] notification in
				guard let self else {
					return
				}

				self.didChangeExternally(notification: notification)
			}
			.store(in: &cancellables)

		// TODO: Replace it with async stream when Swift supports custom executors.
		#if os(iOS) || os(tvOS) || os(visionOS)
		NotificationCenter.default
			.publisher(for: UIScene.willEnterForegroundNotification)
		#elseif os(watchOS)
		NotificationCenter.default
			.publisher(for: WKExtension.applicationWillEnterForegroundNotification)
		#endif
		#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
			.sink { [weak self] notification in
				guard let self else {
					return
				}

				self.willEnterForeground(notification: notification)
			}
			.store(in: cancellables)
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

		for key in self.keys where changedKeys.contains(key.name) {
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

/**
`iCloudSynchronizer` logging related functions.
*/
extension iCloudSynchronizer {
	@available(macOS 11, iOS 14, tvOS 14, watchOS 7, visionOS 1.0, *)
	private static let logger = Logger(OSLog.default)

	private static func logKeySyncStatus(_ key: Defaults.Keys, source: Defaults.DataSource, syncStatus: SyncStatus, value: Any? = nil) {
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

		if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, visionOS 1.0, *) {
			logger.debug("[Defaults.iCloud] \(message)")
		} else {
			#if canImport(OSLog)
			os_log(.debug, log: .default, "[Defaults.iCloud] %@", message)
			#else
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZZZ"
			let dateString = dateFormatter.string(from: Date())
			let processName = ProcessInfo.processInfo.processName
			let processIdentifier = ProcessInfo.processInfo.processIdentifier
			var threadID: UInt64 = 0
			pthread_threadid_np(nil, &threadID)
			print("\(dateString) \(processName)[\(processIdentifier):\(threadID)] [Defaults.iCloud] \(message)")
			#endif
		}
	}
}

extension Defaults {
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

	/**
	Synchronize values with different devices over iCloud.

	There are five ways to initiate synchronization, each of which will create a synchronization task in ``Defaults/iCloud/iCloud``:

	1. Using ``iCloud/add(_:)-5gffb``
	2. Utilizing ``iCloud/syncWithoutWaiting(_:source:)-9cpju``
	3. Observing UserDefaults for added ``Defaults/Defaults/Key`` using Key-Value Observation (KVO)
	4. Monitoring `NSUbiquitousKeyValueStore.didChangeExternallyNotification` for added ``Defaults/Defaults/Key``.
	5. Initializing ``Defaults/Defaults/Keys`` with parameter `iCloud: true`.

	> Tip: After initializing the task, we can call ``iCloud/sync()`` to ensure that all tasks in the backgroundQueue are completed.

	```swift
	import Defaults

	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: true, iCloud: true)
	}

	Task {
		let quality = Defaults.Key<Int>("quality", default: 0)
		Defaults.iCloud.add(quality)
		await Defaults.iCloud.sync() // Optional step: only needed if you require everything to be synced before continuing.
		// Both `isUnicornMode` and `quality` are synced.
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

		/**
		Enable this if you want to call ```` when a value is changed.
		*/
		public static var syncOnChange = false

		/**
		Enable this if you want to debug the syncing status of keys.
		Logs will be printed to the console in OSLog format.

		- Note: The log information will include details such as the key being synced, its corresponding value, and the status of the synchronization.
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
		Explicitly synchronizes in-memory keys and values with those stored on disk.

		As per apple docs, the only recommended time to call this method is upon app launch, or upon returning to the foreground, to ensure that the in-memory key-value store representation is up-to-date.
		*/
		public static func synchronize() {
			synchronizer.synchronize()
		}

		/**
		Wait until synchronization is complete.
		*/
		public static func sync() async {
			await synchronizer.sync()
		}

		/**
		Create synchronization tasks for all the keys that have been added to the ``Defaults/Defaults/iCloud``.
		*/
		public static func syncWithoutWaiting() {
			synchronizer.syncWithoutWaiting()
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source, which can be either a remote server or a local cache.

		- Parameter keys: The keys that should be synced.
		- Parameter source: Sync keys from which data source(remote or local)

		- Note: `source` should be specified if `key` has not been added to ``Defaults/Defaults/iCloud``.
		*/
		public static func syncWithoutWaiting(_ keys: Defaults.Keys..., source: DataSource? = nil) {
			synchronizer.syncWithoutWaiting(keys, source)
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source, which can be either a remote server or a local cache.

		- Parameter keys: The keys that should be synced.
		- Parameter source: Sync keys from which data source(remote or local)

		- Note: `source` should be specified if `key` has not been added to ``Defaults/Defaults/iCloud``.
		*/
		public static func syncWithoutWaiting(_ keys: [Defaults.Keys], source: DataSource? = nil) {
			synchronizer.syncWithoutWaiting(keys, source)
		}
	}
}
