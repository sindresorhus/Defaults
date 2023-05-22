#if !os(macOS)
import UIKit
#endif
import Combine
import Foundation

/// Represent  different data sources available for synchronization.
public enum DataSource {
	/// Using `key.suite` as data source.
	case local
	/// Using `NSUbiquitousKeyValueStore` as data source.
	case remote
}

private enum SyncStatus {
	case start
	case isSyncing
	case finish
}

extension Defaults {
	/**
	Automatically synchronizing ``keys`` when they are changed.
	*/
	public final class iCloud: NSObject {
		override init() {
			self.remoteStorage = NSUbiquitousKeyValueStore.default
			super.init()
			registerNotifications()
			remoteStorage.synchronize()
		}

		init(remoteStorage: KeyValueStore) {
			self.remoteStorage = remoteStorage
			super.init()
			registerNotifications()
			remoteStorage.synchronize()
		}

		deinit {
			removeAll()
		}

		/**
		Set of keys which need to sync.
		*/
		private var keys: Set<Defaults.Keys> = []

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
		A thread-safe synchronization status monitor for `keys`.
		*/
		private var atomicSet: AtomicSet<Defaults.Keys> = .init()

		/**
		Add new key and start to observe its changes.
		*/
		private func add(_ keys: [Defaults.Keys]) {
			self.keys.formUnion(keys)
			for key in keys {
				addObserver(key)
			}
		}

		/**
		Remove key and stop the observation.
		*/
		private func remove(_ keys: [Defaults.Keys]) {
			self.keys.subtract(keys)
			for key in keys {
				removeObserver(key)
			}
		}

		/**
		Remove all sync keys.
		*/
		private func removeAll() {
			for key in keys {
				removeObserver(key)
			}
			keys.removeAll()
			atomicSet.removeAll()
		}

		/**
		Explicitly synchronizes in-memory keys and values with those stored on disk.
		*/
		private func synchronize() {
			remoteStorage.synchronize()
		}

		/**
		Synchronize the specified `keys` from the given `source`.

		- Parameter keys: If the keys parameter is an empty array, the method will use the keys that were added to `Defaults.iCloud`.
		- Parameter source: Sync keys from which data source(remote or local).
		*/
		private func syncKeys(_ keys: [Defaults.Keys] = [], _ source: DataSource? = nil) {
			let keys = keys.isEmpty ? Array(self.keys) : keys
			let latest = source ?? latestDataSource()

			backgroundQueue.sync {
				for key in keys {
					await self.syncKey(key, latest)
				}
			}
		}

		/**
		Synchronize the specified `key` from the  given `source`.

		- Parameter key: The key to synchronize.
		- Parameter source: Sync key from which data source(remote or local).
		*/
		private func syncKey(_ key: Defaults.Keys, _ source: DataSource) async {
			Self.logKeySyncStatus(key, source, .start)
			atomicSet.insert(key)
			await withCheckedContinuation { continuation in
				let completion = {
					continuation.resume()
				}
				switch source {
				case .remote:
					syncFromRemote(key: key, completion)
					recordTimestamp(.local)
				case .local:
					syncFromLocal(key: key, completion)
					recordTimestamp(.remote)
				}
			}
			Self.logKeySyncStatus(key, source, .finish)
			atomicSet.remove(key)
		}

		/**
		Only update the value if it can be retrieved from the remote storage.
		*/
		private func syncFromRemote(key: Defaults.Keys, _ completion: @escaping () -> Void) {
			guard let value = remoteStorage.object(forKey: key.name) else {
				completion()
				return
			}

			Task { @MainActor in
				Defaults.iCloud.logKeySyncStatus(key, .remote, .isSyncing, value)
				key.suite.set(value, forKey: key.name)
				completion()
			}
		}

		/**
		Retrieve a value from local storage, and if it does not exist, remove it from the remote storage.
		*/
		private func syncFromLocal(key: Defaults.Keys, _ completion: @escaping () -> Void) {
			guard let value = key.suite.object(forKey: key.name) else {
				Defaults.iCloud.logKeySyncStatus(key, .local, .isSyncing, nil)
				remoteStorage.removeObject(forKey: key.name)
				syncRemoteStorageOnChange()
				completion()
				return
			}

			Defaults.iCloud.logKeySyncStatus(key, .local, .isSyncing, value)
			remoteStorage.set(value, forKey: key.name)
			syncRemoteStorageOnChange()
			completion()
		}

		/**
		Explicitly synchronizes in-memory keys and values when a value is changed.
		*/
		private func syncRemoteStorageOnChange() {
			if Self.syncOnChange {
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

			return localTimestamp.timeIntervalSince1970 > remoteTimestamp.timeIntervalSince1970 ? .local : .remote
		}
	}
}

extension Defaults.iCloud {
	/**
	The singleton for Defaults's iCloud.
	*/
	static var `default` = Defaults.iCloud()

	/**
	Lists the synced keys.
	*/
	public static let keys = `default`.keys

	/**
	Enable this if you want to call `NSUbiquitousKeyValueStore.synchronize` when value is changed.
	*/
	public static var syncOnChange = false

	/**
	Enable this if you want to debug the syncing status of keys.
	*/
	public static var debug = false

	/**
	Add keys to be automatically synced.
	*/
	public static func add(_ keys: Defaults.Keys...) {
		`default`.add(keys)
	}

	/**
	Remove keys to be automatically synced.
	*/
	public static func remove(_ keys: Defaults.Keys...) {
		`default`.remove(keys)
	}

	/**
	Remove all keys to be automatically synced.
	*/
	public static func removeAll() {
		`default`.removeAll()
	}

	/**
	Explicitly synchronizes in-memory keys and values with those stored on disk.
	*/
	public static func sync() {
		`default`.synchronize()
	}

	/**
	Wait until all synchronization tasks are complete and explicitly synchronizes in-memory keys and values with those stored on disk.
	*/
	public static func sync() async {
		await `default`.backgroundQueue.flush()
		`default`.synchronize()
	}

	/**
	Synchronize all of the keys that have been added to Defaults.iCloud.
	*/
	public static func syncKeys() {
		`default`.syncKeys()
	}

	/**
	Synchronize the specified `keys` from the given `source`,  which could be a remote server or a local cache.

	- Parameter keys: The keys that should be synced.
	- Parameter source: Sync keys from which data source(remote or local)

	- Note: `source` should be specify if `key` has not been added to `Defaults.iCloud`.
	*/
	public static func syncKeys(_ keys: Defaults.Keys..., source: DataSource? = nil) {
		`default`.syncKeys(keys, source)
	}
}

/**
`Defaults.iCloud` notification related functions.
*/
extension Defaults.iCloud {
	private func registerNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(didChangeExternally(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil)
		#if os(iOS) || os(tvOS)
		NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(notification:)), name: UIScene.willEnterForegroundNotification, object: nil)
		#endif
		#if os(watchOS)
		NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(notification:)), name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
		#endif
	}

	@objc
	private func willEnterForeground(notification: Notification) {
		remoteStorage.synchronize()
	}

	@objc
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
			backgroundQueue.sync {
				await self.syncKey(key, .remote)
			}
		}
	}
}

/**
`Defaults.iCloud` observation related functions.
*/
extension Defaults.iCloud {
	private func addObserver(_ key: Defaults.Keys) {
		backgroundQueue.sync {
			key.suite.addObserver(self, forKeyPath: key.name, options: [.new], context: nil)
		}
	}

	private func removeObserver(_ key: Defaults.Keys) {
		backgroundQueue.sync {
			key.suite.removeObserver(self, forKeyPath: key.name, context: nil)
		}
	}

	@_documentation(visibility: private)
	// swiftlint:disable:next block_based_kvo
	override public func observeValue(
		forKeyPath keyPath: String?,
		of object: Any?,
		change: [NSKeyValueChangeKey: Any]?, // swiftlint:disable:this discouraged_optional_collection
		context: UnsafeMutableRawPointer?
	) {
		guard
			let keyPath,
			let object,
			object is UserDefaults,
			let key = keys.first(where: { $0.name == keyPath }),
			!atomicSet.contains(key)
		else {
			return
		}

		backgroundQueue.async {
			self.recordTimestamp(.local)
			await self.syncKey(key, .local)
		}
	}
}

/**
`Defaults.iCloud` logging related functions.
*/
extension Defaults.iCloud {
	private static func logKeySyncStatus(_ key: Defaults.Keys, _ source: DataSource, _ syncStatus: SyncStatus, _ value: Any? = nil) {
		guard Self.debug else {
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
		var valueDescription = ""
		switch syncStatus {
		case .start:
			status = "Start synchronization"
		case .isSyncing:
			status = "Synchronizing"
			valueDescription = "with value '\(value ?? "nil")'"
		case .finish:
			status = "Finish synchronization"
		}
		let message = "\(status) key '\(key.name)' \(valueDescription) \(destination)"

		log(message)
	}

	private static func log(_ message: String) {
		guard Self.debug else {
			return
		}
		let formatter = DateFormatter()
		formatter.dateFormat = "y/MM/dd H:mm:ss.SSSS"
		print("[\(formatter.string(from: Date()))] DEBUG(Defaults) - \(message)")
	}
}
