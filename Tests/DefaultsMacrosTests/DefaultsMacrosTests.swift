import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DefaultsMacrosDeclarations)
@testable import DefaultsMacros
@testable import DefaultsMacrosDeclarations

let testMacros: [String: Macro.Type] = [
	"ObservableDefaults": ObservableDefaultsMacro.self,
]
#endif

final class ObservableDefaultsMacrosTests: XCTestCase {
	func testObservableDefaultsWithKeyPath() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefaults(\.name)
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
						return Defaults[\.name]
					}
					set {
						withMutation(keyPath: \.name) {
							Defaults[\.name] = newValue
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

	func testObservableDefaultsWithFunctionCall() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefaults(getName())
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

	func testObservableDefaultsWithProperty() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			#"""
			@Observable
			class ObservableClass {
				@ObservableDefaults(propertyName)
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
