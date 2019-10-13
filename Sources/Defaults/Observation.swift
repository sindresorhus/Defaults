import Foundation

/// TODO: Nest this inside `Defaults` if Swift ever supported nested protocols.
public protocol DefaultsObservation: AnyObject {
	func invalidate()

	/**
	Keep this observation alive for as long as, and no longer than, another object exists.

	```
	defaults.observe(.xyz) { [unowned self] change in
		self.xyz = change.newValue
	}.tieToLifetime(of: self)
	```
	*/
	@discardableResult
	func tieToLifetime(of weaklyHeldObject: AnyObject) -> Self

	/**
	Break the lifetime tie created by `tieToLifetime(of:)`, if one exists.

	- Postcondition: The effects of any call to `tieToLifetime(of:)` are reversed.
	- Note: If the tied-to object has already died, then self is considered to be invalidated, and this method has no logical effect.
	*/
	func removeLifetimeTie()
}

extension Defaults {
	private static func deserialize<T: Decodable>(_ value: Any?, to type: T.Type) -> T? {
		guard
			let value = value,
			!(value is NSNull)
		else {
			return nil
		}

		// This handles the case where the value was a plist value using `isNativelySupportedType`
		if let value = value as? T {
			return value
		}

		// Using the array trick as done below in `UserDefaults#_set()`
		return [T].init(jsonString: "\([value])")?.first
	}

	fileprivate final class BaseChange {
		fileprivate let kind: NSKeyValueChange
		fileprivate let indexes: IndexSet?
		fileprivate let isPrior: Bool
		fileprivate let newValue: Any?
		fileprivate let oldValue: Any?

		fileprivate init(change: [NSKeyValueChangeKey: Any]) {
			kind = NSKeyValueChange(rawValue: change[.kindKey] as! UInt)!
			indexes = change[.indexesKey] as? IndexSet
			isPrior = change[.notificationIsPriorKey] as? Bool ?? false
			oldValue = change[.oldKey]
			newValue = change[.newKey]
		}
	}

	public struct KeyChange<T: Codable> {
		public let kind: NSKeyValueChange
		public let indexes: IndexSet?
		public let isPrior: Bool
		public let newValue: T
		public let oldValue: T

		fileprivate init(change: BaseChange, defaultValue: T) {
			self.kind = change.kind
			self.indexes = change.indexes
			self.isPrior = change.isPrior
			self.oldValue = deserialize(change.oldValue, to: T.self) ?? defaultValue
			self.newValue = deserialize(change.newValue, to: T.self) ?? defaultValue
		}
	}

	public struct OptionalKeyChange<T: Codable> {
		public let kind: NSKeyValueChange
		public let indexes: IndexSet?
		public let isPrior: Bool
		public let newValue: T?
		public let oldValue: T?

		fileprivate init(change: BaseChange) {
			self.kind = change.kind
			self.indexes = change.indexes
			self.isPrior = change.isPrior
			self.oldValue = deserialize(change.oldValue, to: T.self)
			self.newValue = deserialize(change.newValue, to: T.self)
		}
	}

	private final class UserDefaultsKeyObservation: NSObject, DefaultsObservation {
		fileprivate typealias Callback = (BaseChange) -> Void

		private weak var object: UserDefaults?
		private let key: String
		private let callback: Callback

		fileprivate init(object: UserDefaults, key: String, callback: @escaping Callback) {
			self.object = object
			self.key = key
			self.callback = callback
		}

		deinit {
			invalidate()
		}

		fileprivate func start(options: NSKeyValueObservingOptions) {
			object?.addObserver(self, forKeyPath: key, options: options, context: nil)
		}

		public func invalidate() {
			object?.removeObserver(self, forKeyPath: key, context: nil)
			object = nil
			lifetimeAssociation?.cancel()
		}

		private var lifetimeAssociation: LifetimeAssociation? = nil

		public func tieToLifetime(of weaklyHeldObject: AnyObject) -> Self {
			lifetimeAssociation = LifetimeAssociation(of: self, with: weaklyHeldObject, deinitHandler: { [weak self] in
				self?.invalidate()
			})
			return self
		}

		public func removeLifetimeTie() {
			lifetimeAssociation?.cancel()
		}

		// swiftlint:disable:next block_based_kvo
		override func observeValue(
			forKeyPath keyPath: String?,
			of object: Any?,
			change: [NSKeyValueChangeKey: Any]?, // swiftlint:disable:this discouraged_optional_collection
			context: UnsafeMutableRawPointer?
		) {
			guard let selfObject = self.object else {
				invalidate()
				return
			}

			guard
				selfObject == object as? NSObject,
				let change = change
			else {
				return
			}

			callback(BaseChange(change: change))
		}
	}

	/**
	Observe a defaults key.

	```
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	let observer = Defaults.observe(.isUnicornMode) { change in
		print(change.newValue)
		//=> false
	}
	```
	*/
	public static func observe<T: Codable>(
		_ key: Defaults.Key<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new],
		handler: @escaping (KeyChange<T>) -> Void
	) -> DefaultsObservation {
		let observation = UserDefaultsKeyObservation(object: key.suite, key: key.name) { change in
			handler(
				KeyChange<T>(change: change, defaultValue: key.defaultValue)
			)
		}
		observation.start(options: options)
		return observation
	}

	/**
	Observe an optional defaults key.

	```
	extension Defaults.Keys {
		static let isUnicornMode = OptionalKey<Bool>("isUnicornMode")
	}

	let observer = Defaults.observe(.isUnicornMode) { change in
		print(change.newValue)
		//=> Optional(nil)
	}
	```
	*/
	public static func observe<T: Codable>(
		_ key: Defaults.OptionalKey<T>,
		options: NSKeyValueObservingOptions = [.initial, .old, .new],
		handler: @escaping (OptionalKeyChange<T>) -> Void
	) -> DefaultsObservation {
		let observation = UserDefaultsKeyObservation(object: key.suite, key: key.name) { change in
			handler(
				OptionalKeyChange<T>(change: change)
			)
		}
		observation.start(options: options)
		return observation
	}
}
