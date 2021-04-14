import Foundation

/**
`NativeForm` is a type that we want it to store in the `UserDefaults`
It should have a associated type name `CodableForm` which protocol conform to `Codable`.
So we can convert the json string into `NativeType` like this.
```
guard
	let jsonString = string,
	let jsonData = jsonString.data(using: .utf8),
	let codable = try? JSONDecoder().decode(NativeType.CodableForm.self, from: jsonData)
else {
	return nil
}

return codable.toNative()
```
*/
public protocol DefaultsNativeType: Defaults.Serializable {
	associatedtype CodableForm: Defaults.CodableType
}

/**
`CodableType` is a type that stored in the `UserDefaults` previously, now needs to be migrated.
The main purposed of `CodableType` is trying to infer the `Codable` type to do `JSONDecoder().decode`
It should have an associated type name `NativeForm` which is the type we want it to store in `UserDefaults`.
And it also have a `toNative()` function to convert itself into `NativeForm`.
*/
public protocol DefaultsCodableType: Codable {
	associatedtype NativeForm: Defaults.NativeType
	func toNative() -> NativeForm
}
