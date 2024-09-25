import Defaults
import Foundation

/**
Attached macro that adds support for using ``Defaults`` in ``@Observable`` classes.

- Important: To prevent issues with ``@Observable``, you need to also add ``@ObservationIgnored`` to the attached property.

This macro adds accessor blocks to the attached property similar to those added by `@Observable`.

For example, given the following source:

```swift
@Observable
final class CatModel {
	@Default(.cat)
	@ObservationIgnored
	var catName: String
}
```

The macro will generate the following expansion:

```swift
@Observable
final class CatModel {
	@ObservationIgnored
	var catName: String {
		get {
			access(keypath: \.catName)
			return Defaults[.cat]
		}
		set {
			withMutation(keyPath: \catName) {
				Defaults[.cat] = newValue
			}
		}
	}
}
```
*/
@attached(accessor, names: named(get), named(set))
public macro Default<Value>(_ key: Defaults.Key<Value>) =
	#externalMacro(
		module: "DefaultsMacrosDeclarations",
		type: "DefaultMacro"
	)
