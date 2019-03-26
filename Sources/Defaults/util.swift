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

final class AssociatedObject<T: Any> {
	subscript(index: Any) -> T? {
		get {
			return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T?
		} set {
			objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}

class LifetimeAssociation {
	private(set) weak var object: AnyObject?
	private(set) weak var owner: AnyObject?

	fileprivate init(object weaklyHeldObject: AnyObject, owner weaklyHeldOwner: AnyObject) {
		self.object = weaklyHeldObject
		self.owner = weaklyHeldOwner
	}

	/// Whether the owner is still alive and thus keeping its associated object alive.
	var isValid: Bool {
		return owner != nil
	}

	deinit {
		guard
			let owner = owner,
			var associatedObjects = LifetimeAssociationKeys.associatedObjects[owner],
			let objectIndex = associatedObjects.firstIndex(where: { $0 === object })
		else {
			return
		}
		associatedObjects.remove(at: objectIndex)
		LifetimeAssociationKeys.associatedObjects[owner] = associatedObjects
	}
}

private struct LifetimeAssociationKeys {
	static let associatedObjects = AssociatedObject<[AnyObject]>()
}

func associate(_ object: AnyObject, with owner: AnyObject) -> LifetimeAssociation {
	let associatedObjects = LifetimeAssociationKeys.associatedObjects[owner] ?? []
	LifetimeAssociationKeys.associatedObjects[owner] = associatedObjects + [object]
	return LifetimeAssociation(object: object, owner: owner)
}
