import Foundation
import Combine
#if DEBUG
#if canImport(OSLog)
import OSLog
#endif
#endif


extension String {
	/**
	Get the string as UTF-8 data.
	*/
	var toData: Data { Data(utf8) }
}


extension Decodable {
	init(jsonData: Data) throws {
		self = try JSONDecoder().decode(Self.self, from: jsonData)
	}

	init(jsonString: String) throws {
		try self.init(jsonData: jsonString.toData)
	}
}


final class ObjectAssociation<T> {
	subscript(index: AnyObject) -> T? {
		get {
			objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
		}
		set {
			objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}


/**
Causes a given target object to live at least as long as a given owner object.
*/
final class LifetimeAssociation {
	private class ObjectLifetimeTracker {
		var object: AnyObject?
		var deinitHandler: () -> Void

		init(for weaklyHeldObject: AnyObject, deinitHandler: @escaping () -> Void) {
			self.object = weaklyHeldObject
			self.deinitHandler = deinitHandler
		}

		deinit {
			deinitHandler()
		}
	}

	private static let associatedObjects = ObjectAssociation<[ObjectLifetimeTracker]>()
	private weak var wrappedObject: ObjectLifetimeTracker?
	private weak var owner: AnyObject?

	/**
	Causes the given target object to live at least as long as either the given owner object or the resulting `LifetimeAssociation`, whichever is deallocated first.

	When either the owner or the new `LifetimeAssociation` is destroyed, the given deinit handler, if any, is called.

	```swift
	class Ghost {
		var association: LifetimeAssociation?

		func haunt(_ host: Furniture) {
			association = LifetimeAssociation(of: self, with: host) { [weak self] in
				// Host has been deinitialized
				self?.haunt(seekHost())
			}
		}
	}

	let piano = Piano()
	Ghost().haunt(piano)
	// The Ghost will remain alive as long as `piano` remains alive.
	```

	- Parameter target: The object whose lifetime will be extended.
	- Parameter owner: The object whose lifetime extends the target object's lifetime.
	- Parameter deinitHandler: An optional closure to call when either `owner` or the resulting `LifetimeAssociation` is deallocated.
	*/
	init(of target: AnyObject, with owner: AnyObject, deinitHandler: @escaping () -> Void = {}) {
		let wrappedObject = ObjectLifetimeTracker(for: target, deinitHandler: deinitHandler)

		let associatedObjects = Self.associatedObjects[owner] ?? []
		Self.associatedObjects[owner] = associatedObjects + [wrappedObject]

		self.wrappedObject = wrappedObject
		self.owner = owner
	}

	/**
	Invalidates the association, unlinking the target object's lifetime from that of the owner object. The provided deinit handler is not called.
	*/
	func cancel() {
		wrappedObject?.deinitHandler = {}
		invalidate()
	}

	deinit {
		invalidate()
	}

	private func invalidate() {
		guard
			let owner,
			let wrappedObject,
			var associatedObjects = Self.associatedObjects[owner],
			let wrappedObjectAssociationIndex = associatedObjects.firstIndex(where: { $0 === wrappedObject })
		else {
			return
		}

		associatedObjects.remove(at: wrappedObjectAssociationIndex)
		Self.associatedObjects[owner] = associatedObjects
		self.owner = nil
	}
}


/**
A protocol for making generic type constraints of optionals.

- Note: It's intentionally not including `associatedtype Wrapped` as that limits a lot of the use-cases.
*/
public protocol _DefaultsOptionalProtocol: ExpressibleByNilLiteral {
	/**
	This is useful as you cannot compare `_OptionalType` to `nil`.
	*/
	var _defaults_isNil: Bool { get }
}

extension Optional: _DefaultsOptionalProtocol {
	public var _defaults_isNil: Bool { self == nil }
}


extension Sequence {
	/**
	Returns an array containing the non-nil elements.
	*/
	func compact<T>() -> [T] where Element == T? {
		// TODO: Make this `compactMap(\.self)` when https://github.com/apple/swift/issues/55343 is fixed.
		compactMap { $0 }
	}
}


extension Collection {
	subscript(safe index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}


extension Collection {
	func indexed() -> some Sequence<(Index, Element)> {
		zip(indices, self)
	}
}

extension Defaults {
	@usableFromInline
	static func isValidKeyPath(name: String) -> Bool {
		// The key must be ASCII, not start with @, and cannot contain a dot.
		!name.starts(with: "@") && name.allSatisfy { $0 != "." && $0.isASCII }
	}
}

extension Defaults.Serializable {
	/**
	Cast a `Serializable` value to `Self`.

	Converts a natively supported type from `UserDefaults` into `Self`.

	```swift
	guard let anyObject = object(forKey: key) else {
		return nil
	}

	return Value.toValue(anyObject)
	```
	*/
	static func toValue<T: Defaults.Serializable>(_ anyObject: Any, type: T.Type = Self.self) -> T? {
		if
			T.isNativelySupportedType,
			let anyObject = anyObject as? T
		{
			return anyObject
		}

		guard
			let nextType = T.Serializable.self as? any Defaults.Serializable.Type,
			nextType != T.self
		else {
			// This is a special case for the types which do not conform to `Defaults.Serializable` (for example, `Any`).
			return T.bridge.deserialize(anyObject as? T.Serializable) as? T
		}

		return T.bridge.deserialize(toValue(anyObject, type: nextType) as? T.Serializable) as? T
	}

	/**
	Cast `Self` to `Serializable`.

	Converts `Self` into `UserDefaults` native support type.

	```swift
	set(Value.toSerialize(value), forKey: key)
	```
	*/
	@usableFromInline
	static func toSerializable<T: Defaults.Serializable>(_ value: T) -> Any? {
		if T.isNativelySupportedType {
			return value
		}

		guard let serialized = T.bridge.serialize(value as? T.Value) else {
			return nil
		}

		guard let next = serialized as? any Defaults.Serializable else {
			// This is a special case for the types which do not conform to `Defaults.Serializable` (for example, `Any`).
			return serialized
		}

		return toSerializable(next)
	}
}

// TODO: Remove this in favor of `MutexLock` when targeting Swift 6.
// swiftlint:disable:next final_class
class Lock: DefaultsLockProtocol {
	final class UnfairLock: Lock {
		private let _lock: os_unfair_lock_t

		override init() {
			self._lock = .allocate(capacity: 1)
			_lock.initialize(to: os_unfair_lock())
		}

		override func lock() {
			os_unfair_lock_lock(_lock)
		}

		override func unlock() {
			os_unfair_lock_unlock(_lock)
		}
	}

	@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
	final class AllocatedUnfairLock: Lock {
		private let _lock = OSAllocatedUnfairLock()

		override init() {
			super.init()
		}

		override func lock() {
			_lock.lock()
		}

		override func unlock() {
			_lock.unlock()
		}
	}

	static func make() -> Self {
		guard #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) else {
			return UnfairLock() as! Self
		}

		return AllocatedUnfairLock() as! Self
	}

	private init() {}
	func lock() {}
	func unlock() {}
}

/**
A queue for executing asynchronous tasks in order.

```swift
actor Counter {
	var count = 0

	func increase() {
		count += 1
	}
}
let counter = Counter()
let queue = TaskQueue(priority: .background)
queue.async {
	print(await counter.count) //=> 0
}
queue.async {
	await counter.increase()
}
queue.async {
	print(await counter.count) //=> 1
}
```
*/
final class TaskQueue {
	typealias AsyncTask = @Sendable () async -> Void
	private var queueContinuation: AsyncStream<AsyncTask>.Continuation?
	private let lock: Lock = .make()

	init(priority: TaskPriority? = nil) {
        let (taskStream, queueContinuation) = AsyncStream<AsyncTask>.makeStream()
		self.queueContinuation = queueContinuation

		Task.detached(priority: priority) {
			for await task in taskStream {
				await task()
			}
		}
	}

	deinit {
		queueContinuation?.finish()
	}

	/**
	Queue a new asynchronous task.
	*/
	func async(_ task: @escaping AsyncTask) {
		lock.with {
			queueContinuation?.yield(task)
		}
	}

	/**
	Wait until previous tasks finish.

	```swift
	Task {
		queue.async {
			print("1")
		}
		queue.async {
			print("2")
		}
		await queue.flush()
		//=> 1
		//=> 2
	}
	```
	*/
	func flush() async {
		await withCheckedContinuation { continuation in
			lock.with {
				queueContinuation?.yield {
					continuation.resume()
				}
			}
		}
	}
}

// TODO: Replace with Swift 6 native Atomics support: https://github.com/apple/swift-evolution/blob/main/proposals/0258-property-wrappers.md?rgh-link-date=2024-03-29T14%3A14%3A00Z#changes-from-the-accepted-proposal
@propertyWrapper
final class Atomic<Value> {
	private let lock: Lock = .make()
	private var _value: Value

	var wrappedValue: Value {
		get {
			withValue { $0 }
		}
		set {
			swap(newValue)
		}
	}

	init(value: Value) {
		self._value = value
	}

	@discardableResult
	func withValue<R>(_ action: (Value) -> R) -> R {
		lock.lock()
		defer { lock.unlock() }
		return action(_value)
	}

	@discardableResult
	func modify<R>(_ action: (inout Value) -> R) -> R {
		lock.lock()
		defer { lock.unlock() }
		return action(&_value)
	}

	@discardableResult
	func swap(_ newValue: Value) -> Value {
		modify { (value: inout Value) in
			let oldValue = value
			value = newValue
			return oldValue
		}
	}
}

#if DEBUG
/**
Get SwiftUI dynamic shared object.

Reference: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dyld.3.html
*/
@usableFromInline
let dynamicSharedObject: UnsafeMutableRawPointer = {
	let imageCount = _dyld_image_count()
	for imageIndex in 0..<imageCount {
		guard
			let name = _dyld_get_image_name(imageIndex),
			// Use `/SwiftUI` instead of `SwiftUI` to prevent any library named `XXSwiftUI`.
			String(cString: name).hasSuffix("/SwiftUI"),
			let header = _dyld_get_image_header(imageIndex)
		else {
			continue
		}

		return UnsafeMutableRawPointer(mutating: header)
	}

	return UnsafeMutableRawPointer(mutating: #dsohandle)
}()
#endif

@_transparent
@usableFromInline
func runtimeWarn(
	_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String
) {
#if DEBUG
#if canImport(OSLog)
	let message = message()
	let condition = condition()
	if !condition {
		os_log(
			.fault,
			// A token that identifies the containing executable or dylib image.
			dso: dynamicSharedObject,
			log: OSLog(subsystem: "com.apple.runtime-issues", category: "Defaults"),
			"%@",
			message
		)
	}
#else
	assert(condition, message)
#endif
#endif
}
