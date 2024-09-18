import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct DefaultsMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		DefaultMacro.self
	]
}
