#if canImport(OSLog)
import OSLog
#endif
#if !os(macOS)
import UIKit
#else
import AppKit
#endif
import Combine
import Foundation

/**
Represent  different data sources available for synchronization.
*/
public enum DataSource {
	/// Using `key.suite` as data source.
	case local
	/// Using `NSUbiquitousKeyValueStore` as data source.
	case remote
}

private enum SyncStatus {
	case idle
	case syncing
	case completed
}

extension Defaults {
	public final class iCloudSynchronizer {
		init(remoteStorage: KeyValueStore) {
			self.remoteStorage = remoteStorage
			registerNotifications()
			remoteStorage.synchronize()
		}

		deinit {
			removeAll()
		}

		private var cancellables: Set<AnyCancellable> = []

		/**
		Key for recording the synchronization between `NSUbiquitousKeyValueStore` and `UserDefaults`.
		*/
		private let defaultsSyncKey = "__DEFAULTS__synchronizeTimestamp"

		/**
		A remote key value storage.
		*/
		private var remoteStorage: KeyValueStore

		/**
		A local storage responsible for recording synchronization timestamp.
		*/
		private let localStorage: KeyValueStore = UserDefaults.standard

		/**
		A FIFO queue used to serialize synchronization on keys.
		*/
		private let backgroundQueue = TaskQueue(priority: .background)

		/**
		A thread-safe `keys` that manage the keys to be synced.
		*/
		@Atomic(value: []) private(set) var keys: Set<Defaults.Keys>

		/**
		A thread-safe synchronization status monitor for `keys`.
		*/
		@Atomic(value: []) private var remoteSyncingKeys: Set<Defaults.Keys>

		// TODO: Replace it with async stream when Swift supports custom executors.
		private lazy var localKeysMonitor: CompositeUserDefaultsAnyKeyObservation = .init { [weak self] observable in
			guard
				let self,
				let suite = observable.suite,
				let key = self.keys.first(where: { $0.name == observable.key && $0.suite == suite }),
				// Prevent triggering local observation when syncing from remote.
				!self.remoteSyncingKeys.contains(key)
			else {
				return
			}

			self.backgroundQueue.async {
				self.recordTimestamp(.local)
				await self.syncKey(key, .local)
			}
		}

		/**
		Add new key and start to observe its changes.
		*/
		func add(_ keys: [Defaults.Keys]) {
			self.keys.formUnion(keys)
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

		- Parameter keys: If the keys parameter is an empty array, the method will use the keys that were added to `Defaults.iCloudSynchronizer`.
		- Parameter source: Sync keys from which data source(remote or local).
		*/
		func syncWithoutWaiting(_ keys: [Defaults.Keys] = [], _ source: DataSource? = nil) {
			let keys = keys.isEmpty ? Array(self.keys) : keys
			let latest = source ?? latestDataSource()

			for key in keys {
				backgroundQueue.async {
					await self.syncKey(key, latest)
				}
			}
		}

		/**
		Wait until all synchronization tasks in `backgroundQueue` are complete.
		*/
		func sync() async {
			await backgroundQueue.flush()
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source.

		- Parameter key: The key to synchronize.
		- Parameter source: Sync key from which data source(remote or local).
		*/
		private func syncKey(_ key: Defaults.Keys, _ source: DataSource) async {
			Self.logKeySyncStatus(key, source: source, syncStatus: .idle)
			switch source {
			case .remote:
				await syncFromRemote(key: key)
				recordTimestamp(.local)
			case .local:
				syncFromLocal(key: key)
				recordTimestamp(.remote)
			}
			Self.logKeySyncStatus(key, source: source, syncStatus: .completed)
		}

		/**
		Only update the value if it can be retrieved from the remote storage.
		*/
		private func syncFromRemote(key: Defaults.Keys) async {
			_remoteSyncingKeys.modify { $0.insert(key) }
			await withCheckedContinuation { continuation in
				guard let value = remoteStorage.object(forKey: key.name) else {
					continuation.resume()
					return
				}

				Task { @MainActor in
					Self.logKeySyncStatus(key, source: .remote, syncStatus: .syncing, value: value)
					key.suite.set(value, forKey: key.name)
					continuation.resume()
				}
			}
			_remoteSyncingKeys.modify { $0.remove(key) }
		}

		/**
		Retrieve a value from local storage, and if it does not exist, remove it from the remote storage.
		*/
		private func syncFromLocal(key: Defaults.Keys) {
			guard let value = key.suite.object(forKey: key.name) else {
				Self.logKeySyncStatus(key, source: .local, syncStatus: .syncing, value: nil)
				remoteStorage.removeObject(forKey: key.name)
				syncRemoteStorageOnChange()
				return
			}

			Self.logKeySyncStatus(key, source: .local, syncStatus: .syncing, value: value)
			remoteStorage.set(value, forKey: key.name)
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
		Mark the current timestamp for the specified `source`.
		*/
		private func recordTimestamp(_ source: DataSource) {
			switch source {
			case .local:
				localStorage.set(Date(), forKey: defaultsSyncKey)
			case .remote:
				remoteStorage.set(Date(), forKey: defaultsSyncKey)
			}
		}

		/**
		Determine which data source has the latest data available by comparing the timestamps of the local and remote sources.
		*/
		private func latestDataSource() -> DataSource {
			// If the remote timestamp does not exist, use the local timestamp as the latest data source.
			guard let remoteTimestamp = remoteStorage.object(forKey: defaultsSyncKey) as? Date else {
				return .local
			}
			guard let localTimestamp = localStorage.object(forKey: defaultsSyncKey) as? Date else {
				return .remote
			}

			return localTimestamp > remoteTimestamp ? .local : .remote
		}
	}
}

/**
`Defaults.iCloudSynchronizer` notification related functions.
*/
extension Defaults.iCloudSynchronizer {
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
		#if os(iOS) || os(tvOS)
		NotificationCenter.default
			.publisher(for: UIScene.willEnterForegroundNotification)
		#elseif os(watchOS)
		NotificationCenter.default
			.publisher(for: WKExtension.applicationWillEnterForegroundNotification)
		#endif
		#if os(iOS) || os(tvOS) || os(watchOS)
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
			let remoteTimestamp = remoteStorage.object(forKey: defaultsSyncKey) as? Date
		else {
			return
		}

		if
			let localTimestamp = localStorage.object(forKey: defaultsSyncKey) as? Date,
			localTimestamp > remoteTimestamp
		{
			return
		}

		for key in self.keys where changedKeys.contains(key.name) {
			backgroundQueue.async {
				await self.syncKey(key, .remote)
			}
		}
	}
}

/**
`Defaults.iCloud` logging related functions.
*/
extension Defaults.iCloudSynchronizer {
	@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
	private static let logger = Logger(OSLog.default)

	private static func logKeySyncStatus(_ key: Defaults.Keys, source: DataSource, syncStatus: SyncStatus, value: Any? = nil) {
		guard Defaults.iCloud.isDebug else {
			return
		}
		var destination: String
		switch source {
		case .local:
			destination = "from local"
		case .remote:
			destination = "from remote"
		}
		var status: String
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

		if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
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
	Automatically create synchronization tasks when the added `keys` undergo changed.

	The synchronization task will be created in three different ways.

	1. UserDefaults changes.
	2. Receive `NSUbiquitousKeyValueStore.didChangeExternallyNotification`.
	3. Call `syncWithoutWaiting()`.

	> Tip: Using `await sync()` to make sure all synchronization tasks are done.

	```swift
	let quality = Defaults.Key<Int>("quality", default: 0, iCloud: true)
	Defaults[quality] = 1
	await Defaults.iCloud.sync()
	print(NSUbiquitousKeyValueStore.default.object(forKey: quality.name)) //=> 1
	```
	*/
	public enum iCloud {
		/**
		The singleton for Defaults's iCloudSynchronizer.
		*/
		static var synchronizer = Defaults.iCloudSynchronizer(remoteStorage: NSUbiquitousKeyValueStore.default)

		/**
		Lists the synced keys.
		*/
		public static let keys = synchronizer.keys

		/**
		Enable this if you want to call `NSUbiquitousKeyValueStore.synchronize` when a value is changed.
		*/
		public static var syncOnChange = false

		/**
		Enable this if you want to debug the syncing status of keys.
		*/
		public static var isDebug = false

		/**
		Add the keys to be automatically synced.
		*/
		public static func add(_ keys: Defaults.Keys...) {
			synchronizer.add(keys)
		}

		/**
		 Remove the keys that are set to be automatically synced.
		*/
		public static func remove(_ keys: Defaults.Keys...) {
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
		*/
		public static func synchronize() {
			synchronizer.synchronize()
		}

		/**
		Wait until all synchronization tasks are complete.
		*/
		public static func sync() async {
			await synchronizer.sync()
		}

		/**
		Create synchronization tasks for all the keys that have been added to the `Defaults.iCloud`.
		*/
		public static func syncWithoutWaiting() {
			synchronizer.syncWithoutWaiting()
		}

		/**
		Create synchronization tasks for the specified `keys` from the given source, which can be either a remote server or a local cache.

		- Parameter keys: The keys that should be synced.
		- Parameter source: Sync keys from which data source(remote or local)

		- Note: `source` should be specify if `key` has not been added to `Defaults.iCloud`.
		*/
		public static func syncWithoutWaiting(_ keys: Defaults.Keys..., source: DataSource? = nil) {
			synchronizer.syncWithoutWaiting(keys, source)
		}
	}
}
