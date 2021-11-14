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

		let associatedObjects = LifetimeAssociation.associatedObjects[owner] ?? []
		LifetimeAssociation.associatedObjects[owner] = associatedObjects + [wrappedObject]

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
			let owner = owner,
			let wrappedObject = wrappedObject,
			var associatedObjects = LifetimeAssociation.associatedObjects[owner],
			let wrappedObjectAssociationIndex = associatedObjects.firstIndex(where: { $0 === wrappedObject })
		else {
			return
		}

		associatedObjects.remove(at: wrappedObjectAssociationIndex)
		LifetimeAssociation.associatedObjects[owner] = associatedObjects
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
		// TODO: Make this `compactMap(\.self)` when https://bugs.swift.org/browse/SR-12897 is fixed.
		compactMap { $0 }
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
	static func toValue(_ anyObject: Any) -> Self? {
		// Return directly if `anyObject` can cast to Value, since it means `Value` is a natively supported type.
		if
			isNativelySupportedType,
			let anyObject = anyObject as? Self
		{
			return anyObject
		} else if let value = bridge.deserialize(anyObject as? Serializable) {
			return value as? Self
		}

		return nil
	}

	/**
	Cast `Self` to `Serializable`.

	Converts `Self` into `UserDefaults` native support type.

	```
	set(Value.toSerialize(value), forKey: key)
	```
	*/
	static func toSerializable(_ value: Self) -> Any? {
		// Return directly if `Self` is a natively supported type, since it does not need serialization.
		if isNativelySupportedType {
			return value
		} else if let serialized = bridge.serialize(value as? Value) {
			return serialized
		}

		return nil
	}
}
