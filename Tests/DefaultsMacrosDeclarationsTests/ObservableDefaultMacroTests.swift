import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

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

final class ObservableDefaultMacroTests: XCTestCase {
	func testExpansionWithMemberSyntax() throws {
		#if canImport(DefaultsMacrosDeclarations)
		assertMacroExpansion(
			declaration(for: "Defaults.Keys.name"),
			expandedSource: expectedExpansion(for: "Defaults.Keys.name"),
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
			declaration(for: ".name"),
			expandedSource: expectedExpansion(for: ".name"),
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
			declaration(for: "getName()"),
			expandedSource: expectedExpansion(for: "getName()"),
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
			declaration(for: "propertyName"),
			expandedSource: expectedExpansion(for: "propertyName"),
			macros: testMacros,
			indentationWidth: .tabs(1)
		)
		#else
		throw XCTSkip("Macros are only supported when running tests for the host platform")
		#endif
	}

	private func declaration(for keyExpression: String) -> String {
		#"""
		@Observable
		class ObservableClass {
			@ObservableDefault(\#(keyExpression))
			@ObservationIgnored
			var name: String
		}
		"""#
	}

	private func expectedExpansion(for keyExpression: String) -> String {
		#"""
		@Observable
		class ObservableClass {
			@ObservationIgnored
			var name: String {
				get {
					if objc_getAssociatedObject(self, &Self._objcAssociatedKey_name) == nil {
						let cancellable = Defaults.publisher(\#(keyExpression))
							.sink { [weak self] change in
								Defaults.withoutPropagation {
									self?.name = change.newValue
								}
							}
						objc_setAssociatedObject(self, &Self._objcAssociatedKey_name, cancellable, .OBJC_ASSOCIATION_RETAIN)
					}
					access(keyPath: \.name)
					return Defaults[\#(keyExpression)]
				}
				set {
					withMutation(keyPath: \.name) {
						Defaults[\#(keyExpression)] = newValue
					}
				}
			}

			private nonisolated(unsafe) static var _objcAssociatedKey_name: Void?
		}
		"""#
	}
}
