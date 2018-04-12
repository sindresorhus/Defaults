// MIT License © Sindre Sorhus
import Cocoa

public class DefaultsKeys {
	fileprivate init() {}
}

public final class DefaultsKey<T: Codable>: DefaultsKeys {
	fileprivate let name: String
	fileprivate let defaultValue: T

	public init(_ key: String, default defaultValue: T) {
		self.name = key
		self.defaultValue = defaultValue
	}
}

public final class DefaultsOptionalKey<T: Codable>: DefaultsKeys {
	fileprivate let name: String

	public init(_ key: String) {
		self.name = key
	}
}

// Has to be `defaults` lowercase until Swift supports static subscripts…
public let Defaults = UserDefaults.standard

public extension UserDefaults {
	private func _get<T: Codable>(_ key: String) -> T? {
		if isNativelySupportedType(T.self) {
			return object(forKey: key) as? T
		}

		guard let text = string(forKey: key),
			let data = "[\(text)]".data(using: .utf8) else {
				return nil
		}

		do {
			return (try JSONDecoder().decode([T].self, from: data)).first
		} catch {
			print(error)
		}

		return nil
	}

	private func _set<T: Codable>(_ key: String, to value: T) {
		if isNativelySupportedType(T.self) {
			set(value, forKey: key)
			return
		}

		do {
			// Some codable values like URL and enum are encoded as a top-level
			// string which JSON can't handle, so we need to wrap it in an array
			// We need this: https://forums.swift.org/t/allowing-top-level-fragments-in-jsondecoder/11750
			let data = try JSONEncoder().encode([value])
			let string = String(data: data, encoding: .utf8)?.dropFirst().dropLast()
			set(string, forKey: key)
		} catch {
			print(error)
		}
	}

	public subscript<T: Codable>(key: DefaultsKey<T>) -> T {
		get {
			return _get(key.name) ?? key.defaultValue
		}
		set {
			_set(key.name, to: newValue)
		}
	}

	public subscript<T: Codable>(key: DefaultsOptionalKey<T>) -> T? {
		get {
			return _get(key.name)
		}
		set {
			if let value = newValue {
				_set(key.name, to: value)
			}
		}
	}

	private func isNativelySupportedType<T>(_ type: T.Type) -> Bool {
		switch type {
		case is Bool.Type,
			 is String.Type,
			 is Int.Type,
			 is Double.Type,
			 is Float.Type,
			 is Date.Type:
			return true
		default:
			return false
		}
	}

	public func clear() {
		for key in dictionaryRepresentation().keys {
			removeObject(forKey: key)
		}
	}
}
