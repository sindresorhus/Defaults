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


/// A protocol for making generic type constraints of optionals.
/// - Note: It's intentionally not including `associatedtype Wrapped` as that limits a lot of the use-cases.
public protocol _DefaultsOptionalType: ExpressibleByNilLiteral {
	/// This is useful as you can't compare `_OptionalType` to `nil`.
	var isNil: Bool { get }
}

extension Optional: _DefaultsOptionalType {
	public var isNil: Bool { self == nil }
}

func isOptionalType<T>(_ type: T.Type) -> Bool {
	type is _DefaultsOptionalType.Type
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


public protocol DefaultsSerializable {
	typealias Value = Bridge.Value
	associatedtype Bridge: DefaultsBridge
	static var bridge: Bridge { get }
	static var isString: Bool { get }
	static var isURL: Bool { get }
	static var isArray: Bool { get }
	static var isDictionary: Bool { get }
}

public protocol DefaultsBridge {
	// The type of Value of Key<Value>
	associatedtype Value

	// This type should be one of the NativelySupportedType
	associatedtype Serializable

	// Customize set behavior in UserDefaults
	func set(_ value: Value?)

	// Serialize Value to Serializable before we store it in UserDefaults
	func serialize(_ value: Value?) -> Serializable?

	// Deserialize to Value to let user used it
	func deserialize(_ object: Any) -> Value?
}

extension DefaultsSerializable {
	public static var isString: Bool { false }
	public static var isURL: Bool { false }
	public static var isArray: Bool { false }
	public static var isDictionary: Bool { false }
}

extension DefaultsBridge {
	public func set(_ value: Value?) {
		return
	}
}

extension Optional: DefaultsSerializable where Wrapped: DefaultsSerializable {
	public static var isString: Bool { Wrapped.isString }

	public static var isURL: Bool { Wrapped.isURL }

	public static var isArray: Bool { Wrapped.isArray }

	public static var isDictionary: Bool { Wrapped.isDictionary }

	public static var bridge: DefaultsOptionalBridge<Wrapped.Bridge> { return DefaultsOptionalBridge(bridge: Wrapped.bridge) }
}

extension DefaultsSerializable where Self: Codable {
	public static var bridge: DefaultsCodableBridge<Self> { return DefaultsCodableBridge<Self>() }
}

extension DefaultsSerializable where Self: RawRepresentable {
	public static var bridge: DefaultsRawRepresentableBridge<Self> { return DefaultsRawRepresentableBridge() }
}

extension Data: DefaultsSerializable {}
extension String: DefaultsSerializable {
	public static var isString: Bool { true }
}
extension Date: DefaultsSerializable {}
extension Bool: DefaultsSerializable {}
extension Int: DefaultsSerializable {}
extension Double: DefaultsSerializable {}
extension Float: DefaultsSerializable {}
extension URL: DefaultsSerializable {
	public static var isURL: Bool { true }
}

extension Array: DefaultsSerializable where Element: DefaultsSerializable {
	public static var bridge: DefaultsArrayBridge<Element> { return DefaultsArrayBridge() }
	public static var isArray: Bool { true }
}

extension Dictionary: DefaultsSerializable where Key == String, Value: DefaultsSerializable {
	public static var bridge: DefaultsObjectBridge<Value> { return DefaultsObjectBridge() }
	public static var isDictionary: Bool { true }
}