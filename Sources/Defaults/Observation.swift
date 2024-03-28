import Foundation

public protocol _DefaultsObservation: AnyObject {
	func invalidate()

	/**
	Keep this observation alive for as long as, and no longer than, another object exists.

	```swift
	Defaults.observe(.xyz) { [unowned self] change in
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
	public typealias Observation = _DefaultsObservation

	public enum ObservationOption: Sendable {
		/**
		Whether a notification should be sent to the observer immediately, before the observer registration method even returns.
		*/
		case initial

		/**
		Whether separate notifications should be sent to the observer before and after each change, instead of a single notification after the change.
		*/
		case prior
	}

	public typealias ObservationOptions = Set<ObservationOption>

	private static func deserialize<Value: Serializable>(_ value: Any?, to type: Value.Type) -> Value? {
		guard
			let value,
			!(value is NSNull)
		else {
			return nil
		}

		return Value.toValue(value)
	}

	struct BaseChange {
		let kind: NSKeyValueChange
		let indexes: IndexSet?
		let isPrior: Bool
		let newValue: Any?
		let oldValue: Any?

		init(change: [NSKeyValueChangeKey: Any]) {
			self.kind = NSKeyValueChange(rawValue: change[.kindKey] as! UInt)!
			self.indexes = change[.indexesKey] as? IndexSet
			self.isPrior = change[.notificationIsPriorKey] as? Bool ?? false
			self.oldValue = change[.oldKey]
			self.newValue = change[.newKey]
		}
	}

	public struct KeyChange<Value: Serializable> {
		public let kind: NSKeyValueChange
		public let indexes: IndexSet?
		public let isPrior: Bool
		public let newValue: Value
		public let oldValue: Value

		init(change: BaseChange, defaultValue: Value) {
			self.kind = change.kind
			self.indexes = change.indexes
			self.isPrior = change.isPrior
			self.oldValue = deserialize(change.oldValue, to: Value.self) ?? defaultValue
			self.newValue = deserialize(change.newValue, to: Value.self) ?? defaultValue
		}
	}

	private static var preventPropagationThreadDictionaryKey: String {
		"\(type(of: Observation.self))_threadUpdatingValuesFlag"
	}

	/**
	Execute the closure without triggering change events.

	Any `Defaults` key changes made within the closure will not propagate to `Defaults` event listeners (`Defaults.observe()` and `Defaults.publisher()`). This can be useful to prevent infinite recursion when you want to change a key in the callback listening to changes for the same key.

	- Note: This only works with `Defaults.observe()` and `Defaults.publisher()`. User-made KVO will not be affected.

	```swift
	let observer = Defaults.observe(keys: .key1, .key2) {
		// …

		Defaults.withoutPropagation {
			// Update `.key1` without propagating the change to listeners.
			Defaults[.key1] = 11
		}

		// This will be propagated.
		Defaults[.someKey] = true
	}
	```
	*/
	public static func withoutPropagation(_ closure: () -> Void) {
		// How does it work?
		// KVO observation callbacks are executed right after a change is made, and run on the same thread as the caller. So it works by storing a flag in the current thread's dictionary, which is then evaluated in the callback.

		let key = preventPropagationThreadDictionaryKey
		Thread.current.threadDictionary[key] = true
		closure()
		Thread.current.threadDictionary[key] = false
	}

	final class UserDefaultsKeyObservation: NSObject, Observation {
		typealias Callback = (BaseChange) -> Void

		private weak var object: UserDefaults?
		private let key: String
		private let callback: Callback
		private var isObserving = false

		init(object: UserDefaults, key: String, callback: @escaping Callback) {
			self.object = object
			self.key = key
			self.callback = callback
		}

		deinit {
			invalidate()
		}

		func start(options: ObservationOptions) {
			object?.addObserver(self, forKeyPath: key, options: options.toNSKeyValueObservingOptions, context: nil)
			isObserving = true
		}

		func invalidate() {
			if isObserving {
				object?.removeObserver(self, forKeyPath: key, context: nil)
				isObserving = false
			}

			object = nil
			lifetimeAssociation?.cancel()
		}

		private var lifetimeAssociation: LifetimeAssociation?

		func tieToLifetime(of weaklyHeldObject: AnyObject) -> Self {
			// swiftlint:disable:next trailing_closure
			lifetimeAssociation = LifetimeAssociation(of: self, with: weaklyHeldObject, deinitHandler: { [weak self] in
				self?.invalidate()
			})

			return self
		}

		func removeLifetimeTie() {
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
				let change
			else {
				return
			}

			let key = preventPropagationThreadDictionaryKey
			let updatingValuesFlag = (Thread.current.threadDictionary[key] as? Bool) ?? false
			guard !updatingValuesFlag else {
				return
			}
			callback(BaseChange(change: change))
		}
	}

	final class SuiteKeyPair: Hashable {
		weak var suite: UserDefaults?
		let key: String

		init(suite: UserDefaults, key: String) {
			self.suite = suite
			self.key = key
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(key)
			hasher.combine(suite)
		}

		static func == (lhs: SuiteKeyPair, rhs: SuiteKeyPair) -> Bool {
			lhs.key == rhs.key
				&& lhs.suite == rhs.suite
		}
	}

	private final class CompositeUserDefaultsKeyObservation: NSObject, Observation {
		private static var observationContext = 0

		private var observables: [SuiteKeyPair]
		private var lifetimeAssociation: LifetimeAssociation?
		private let callback: UserDefaultsKeyObservation.Callback

		init(observables: [(suite: UserDefaults, key: String)], callback: @escaping UserDefaultsKeyObservation.Callback) {
			self.observables = observables.map { SuiteKeyPair(suite: $0.suite, key: $0.key) }
			self.callback = callback
			super.init()
		}

		deinit {
			invalidate()
		}

		func start(options: ObservationOptions) {
			for observable in observables {
				observable.suite?.addObserver(
					self,
					forKeyPath: observable.key,
					options: options.toNSKeyValueObservingOptions,
					context: &Self.observationContext
				)
			}
		}

		func invalidate() {
			for observable in observables {
				observable.suite?.removeObserver(self, forKeyPath: observable.key, context: &Self.observationContext)
				observable.suite = nil
			}

			lifetimeAssociation?.cancel()
		}

		func tieToLifetime(of weaklyHeldObject: AnyObject) -> Self {
			// swiftlint:disable:next trailing_closure
			lifetimeAssociation = LifetimeAssociation(of: self, with: weaklyHeldObject, deinitHandler: { [weak self] in
				self?.invalidate()
			})

			return self
		}

		func removeLifetimeTie() {
			lifetimeAssociation?.cancel()
		}

		// swiftlint:disable:next block_based_kvo
		override func observeValue(
			forKeyPath keyPath: String?,
			of object: Any?,
			change: [NSKeyValueChangeKey: Any]?, // swiftlint:disable:this discouraged_optional_collection
			context: UnsafeMutableRawPointer?
		) {
			guard
				context == &Self.observationContext
			else {
				super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
				return
			}

			guard
				object is UserDefaults,
				let change
			else {
				return
			}

			let key = preventPropagationThreadDictionaryKey
			let updatingValuesFlag = (Thread.current.threadDictionary[key] as? Bool) ?? false
			if updatingValuesFlag {
				return
			}

			callback(BaseChange(change: change))
		}
	}

	final class CompositeUserDefaultsAnyKeyObservation: NSObject, Observation {
		typealias Callback = (SuiteKeyPair) -> Void
		private static var observationContext = 1

		private var observables: Set<SuiteKeyPair> = []
		private var lifetimeAssociation: LifetimeAssociation?
		private let callback: CompositeUserDefaultsAnyKeyObservation.Callback

		init(_ callback: @escaping CompositeUserDefaultsAnyKeyObservation.Callback) {
			self.callback = callback
		}

		func addObserver(_ key: Defaults._AnyKey, options: ObservationOptions = []) {
			let keyPair: SuiteKeyPair = .init(suite: key.suite, key: key.name)
			let (inserted, observable) = observables.insert(keyPair)
			guard inserted else {
				return
			}

			observable.suite?.addObserver(self, forKeyPath: observable.key, options: options.toNSKeyValueObservingOptions, context: &Self.observationContext)
		}

		func removeObserver(_ key: Defaults._AnyKey) {
			let keyPair: SuiteKeyPair = .init(suite: key.suite, key: key.name)
			guard let observable = observables.remove(keyPair) else {
				return
			}

			observable.suite?.removeObserver(self, forKeyPath: observable.key, context: &Self.observationContext)
		}

		@discardableResult
		func tieToLifetime(of weaklyHeldObject: AnyObject) -> Self {
			// swiftlint:disable:next trailing_closure
			lifetimeAssociation = LifetimeAssociation(of: self, with: weaklyHeldObject, deinitHandler: { [weak self] in
				self?.invalidate()
			})

			return self
		}

		func removeLifetimeTie() {
			lifetimeAssociation?.cancel()
		}

		func invalidate() {
			for observable in observables {
				observable.suite?.removeObserver(self, forKeyPath: observable.key, context: &Self.observationContext)
				observable.suite = nil
			}

			observables.removeAll()
			lifetimeAssociation?.cancel()
		}

		// swiftlint:disable:next block_based_kvo
		override func observeValue(
			forKeyPath keyPath: String?,
			of object: Any?,
			change: [NSKeyValueChangeKey: Any]?, // swiftlint:disable:this discouraged_optional_collection
			context: UnsafeMutableRawPointer?
		) {
			guard
				context == &Self.observationContext
			else {
				super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
				return
			}

			guard
				let object = object as? UserDefaults,
				let keyPath,
				let observable = observables.first(where: { $0.key == keyPath && $0.suite == object })
			else {
				return
			}

			callback(observable)
		}
	}

	/**
	Observe a defaults key.

	```swift
	extension Defaults.Keys {
		static let isUnicornMode = Key<Bool>("isUnicornMode", default: false)
	}

	let observer = Defaults.observe(.isUnicornMode) { change in
		print(change.newValue)
		//=> false
	}
	```

	- Warning: This method exists for backwards compatibility and will be deprecated sometime in the future. Use ``Defaults/updates(_:initial:)-88orv`` instead.
	*/
	public static func observe<Value: Serializable>(
		_ key: Key<Value>,
		options: ObservationOptions = [.initial],
		handler: @escaping (KeyChange<Value>) -> Void
	) -> Observation {
		let observation = UserDefaultsKeyObservation(object: key.suite, key: key.name) { change in
			handler(
				KeyChange(change: change, defaultValue: key.defaultValue)
			)
		}
		observation.start(options: options)
		return observation
	}

	/**
	Observe multiple keys of any type, but without any information about the changes.

	```swift
	extension Defaults.Keys {
		static let setting1 = Key<Bool>("setting1", default: false)
		static let setting2 = Key<Bool>("setting2", default: true)
	}

	let observer = Defaults.observe(keys: .setting1, .setting2) {
		// …
	}
	```

	- Warning: This method exists for backwards compatibility and will be deprecated sometime in the future. Use ``Defaults/updates(_:initial:)-88orv`` instead.
	*/
	public static func observe(
		keys: _AnyKey...,
		options: ObservationOptions = [.initial],
		handler: @escaping () -> Void
	) -> Observation {
		let pairs = keys.map {
			(suite: $0.suite, key: $0.name)
		}
		let compositeObservation = CompositeUserDefaultsKeyObservation(observables: pairs) { _ in
			handler()
		}
		compositeObservation.start(options: options)

		return compositeObservation
	}
}

extension Defaults.ObservationOptions {
	var toNSKeyValueObservingOptions: NSKeyValueObservingOptions {
		var options: NSKeyValueObservingOptions = [.old, .new]

		if contains(.initial) {
			options.insert(.initial)
		} else if contains(.prior) {
			options.insert(.prior)
		}

		return options
	}
}

extension Defaults.KeyChange: Equatable where Value: Equatable {}
extension Defaults.KeyChange: Sendable where Value: Sendable {}
