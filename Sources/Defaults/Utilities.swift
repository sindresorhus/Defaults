import Foundation


extension Decodable {
	init?(jsonData: Data) {
		guard let value = try? JSONDecoder().decode(Self.self, from: jsonData) else {
			return nil
		}

		self = value
	}

	init?(jsonString: String) {
		guard let data = jsonString.data(using: .utf8) else {
			return nil
		}

		self.init(jsonData: data)
	}
}


final class ObjectAssociation<T: Any> {
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

	```
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
public protocol _DefaultsOptionalType: ExpressibleByNilLiteral {
	/**
	This is useful as you cannot compare `_OptionalType` to `nil`.
	*/
	var isNil: Bool { get }
}

extension Optional: _DefaultsOptionalType {
	public var isNil: Bool { self == nil }
}


extension DispatchQueue {
	/**
	Performs the `execute` closure immediately if we're on the main thread or asynchronously puts it on the main thread otherwise.
	*/
	static func mainSafeAsync(execute work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			main.async(execute: work)
		}
	}
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


extension Defaults.Serializable {
	/**
	Cast a `Serializable` value to `Self`.

	Converts a natively supported type from `UserDefaults` into `Self`.

	```
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
		guard let nextType = T.Serializable.self as? any Defaults.Serializable.Type else {
			// This is a special case for the types which do not conform to `Defaults.Serializable`(ex. `Any`).
			return T.bridge.deserialize(anyObject as? T.Serializable) as? T
		}

		return T.bridge.deserialize(toValue(anyObject, type: nextType) as? T.Serializable) as? T
	}

	/**
	Cast `Self` to `Serializable`.

	Converts `Self` into `UserDefaults` native support type.

	```
	set(Value.toSerialize(value), forKey: key)
	```
	*/
	static func toSerializable<T: Defaults.Serializable>(_ value: T) -> Any? {
		if T.isNativelySupportedType {
			return value
		}
		guard let serialized = T.bridge.serialize(value as? T.Value) else {
			return nil
		}
		guard let next = serialized as? any Defaults.Serializable else {
			// This is a special case for the types which do not conform to `Defaults.Serializable`(ex. `Any`).
			return serialized
		}
		return toSerializable(next)
	}
}
