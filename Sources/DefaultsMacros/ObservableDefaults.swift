import Defaults
import Foundation

/**
Attached macro that adds support for using ``Defaults`` in ``@Observable`` classes. **Important**: to
prevent issues with ``@Observable``, you'll need to also add ``@ObservationIgnored`` to the attached
property.

This macro adds accessor blocks to the attached property similar to those added by `@Observable`.
For example, given the following source:

```swift
@Observable
final class CatModel {
	@ObservableDefaults(Defaults.Keys.cat)
	@ObservationIgnored
	private var catName: String
}
```

The macro will generate the following expansion:

```swift
@Observable
final class CatModel {
	@ObservationIgnored
	private var catName: String {
		get {
			access(keypath: \.catName)
			return Defaults[Defaults.Keys.cat]
		}
		set {
			withMutation(keyPath: \catName) {
				Defaults[Defaults.Keys.cat] = newValue
			}
		}
	}
}
```
*/
@attached(accessor, names: named(get), named(set))
public macro ObservableDefaults<Value>(_ key: Defaults.Key<Value>) =
	#externalMacro(
		module: "DefaultsMacrosDeclarations",
		type: "ObservableDefaultsMacro"
	)
