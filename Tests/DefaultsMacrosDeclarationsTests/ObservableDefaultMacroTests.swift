import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DefaultsMacrosDeclarations)
@testable import DefaultsMacros
@testable import DefaultsMacrosDeclarations

let testMacros: [String: Macro.Type] = [
	"ObservableDefault": ObservableDefaultMacro.self
]
#else
let testMacros: [String: Macro.Type] = [:]
#endif

@Suite(.serialized)
final class ObservableDefaultMacroTests {
	@Test(.disabled(if: testMacros.isEmpty))
	func testExpansionWithMemberSyntax() throws {
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefault(Defaults.Keys.name)
				@ObservationIgnored
				var name: String
			}
			"""#,
			expandedSource:
			#"""
			@Observable
			class ObservableClass {
				@ObservationIgnored
				var name: String {
					get {
						access(keyPath: \.name)
						return Defaults[Defaults.Keys.name]
					}
					set {
						withMutation(keyPath: \.name) {
							Defaults[Defaults.Keys.name] = newValue
						}
					}
				}
			}
			"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	@Test(.disabled(if: testMacros.isEmpty))
	func testExpansionWithDotSyntax() throws {
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefault(.name)
				@ObservationIgnored
				var name: String
			}
			"""#,
			expandedSource:
			#"""
			@Observable
			class ObservableClass {
				@ObservationIgnored
				var name: String {
					get {
						access(keyPath: \.name)
						return Defaults[.name]
					}
					set {
						withMutation(keyPath: \.name) {
							Defaults[.name] = newValue
						}
					}
				}
			}
			"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	@Test(.disabled(if: testMacros.isEmpty))
	func testExpansionWithFunctionCall() throws {
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefault(getName())
				@ObservationIgnored
				var name: String
			}
			"""#,
			expandedSource:
			#"""
			@Observable
			class ObservableClass {
				@ObservationIgnored
				var name: String {
					get {
						access(keyPath: \.name)
						return Defaults[getName()]
					}
					set {
						withMutation(keyPath: \.name) {
							Defaults[getName()] = newValue
						}
					}
				}
			}
			"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}

	@Test(.disabled(if: testMacros.isEmpty))
	func testExpansionWithProperty() throws {
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefault(propertyName)
				@ObservationIgnored
				var name: String
			}
			"""#,
			expandedSource:
			#"""
			@Observable
			class ObservableClass {
				@ObservationIgnored
				var name: String {
					get {
						access(keyPath: \.name)
						return Defaults[propertyName]
					}
					set {
						withMutation(keyPath: \.name) {
							Defaults[propertyName] = newValue
						}
					}
				}
			}
			"""#,
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
	}
}
