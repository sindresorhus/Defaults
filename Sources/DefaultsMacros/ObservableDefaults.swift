import Foundation

import Defaults

@attached(accessor, names: named(get), named(set))
public macro ObservableDefaults<Value>(_ key: Defaults.Key<Value>) =
	#externalMacro(
		module: "DefaultsMacrosDeclarations",
		type: "ObservableDefaultsMacro"
	)
