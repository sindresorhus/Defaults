import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DefaultsMacrosDeclarations)
@testable import DefaultsMacros
@testable import DefaultsMacrosDeclarations

let testMacros: [String: Macro.Type] = [
	"Default": DefaultMacro.self,
]
#endif

final class DefaultMacroTests: XCTestCase {
	func testExpansionWithMemberSyntax() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@Default(Defaults.Keys.name)
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
		#else
		throw XCTSkip("Macros are only supported when running tests for the host platform")
		#endif
	}

	func testExpansionWithDotSyntax() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@Default(.name)
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
		#else
		throw XCTSkip("Macros are only supported when running tests for the host platform")
		#endif
	}

	func testExpansionWithFunctionCall() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@Default(getName())
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
		#else
		throw XCTSkip("Macros are only supported when running tests for the host platform")
		#endif
	}

	func testExpansionWithProperty() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@Default(propertyName)
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
		#else
		throw XCTSkip("Macros are only supported when running tests for the host platform")
		#endif
	}
}
