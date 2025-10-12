import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/**
 Macro declaration for the ``ObservableDefault`` macro.
*/
public struct ObservableDefaultMacro {}

/**
Conforming to ``AccessorMacro`` allows us to add the property accessors (get/set) that integrate with ``Observable``.
*/
extension ObservableDefaultMacro: AccessorMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws(ObservableDefaultMacroError) -> [AccessorDeclSyntax] {
		let property = try propertyPattern(of: declaration)
		let expression = try keyExpression(of: node)
		let associatedKey = associatedKeyToken(for: property)

		// The get/set accessors follow the same pattern that @Observable uses to handle the mutations.
		//
		// The get accessor also sets up an observation to update the value when the UserDefaults
		// changes from elsewhere. Doing so requires attaching it as an Objective-C associated
		// object due to limitations with current macro capabilities and Swift concurrency.
		//
		// To prevent infinite recursion, we use Defaults.withoutPropagation in the observation
		// callback. This ensures that when the callback updates the property, it doesn't trigger
		// observers again, while still allowing normal writes to propagate to other observers.
		return [
			#"""
			get {
				if objc_getAssociatedObject(self, &Self.\#(associatedKey)) == nil {
					let cancellable = Defaults.publisher(\#(expression))
						.sink { [weak self] change in
							Defaults.withoutPropagation {
								self?.\#(property) = change.newValue
							}
						}
					objc_setAssociatedObject(self, &Self.\#(associatedKey), cancellable, .OBJC_ASSOCIATION_RETAIN)
				}
				access(keyPath: \.\#(property))
				return Defaults[\#(expression)]
			}
			"""#,
			#"""
			set {
				withMutation(keyPath: \.\#(property)) {
					Defaults[\#(expression)] = newValue
				}
			}
			"""#
		]
	}
}

/**
Conforming to ``PeerMacro`` we can add a new property of type Defaults.Observation that will update the original property whenever
the UserDefaults value changes outside the class.
*/
extension ObservableDefaultMacro: PeerMacro {
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.DeclSyntax] {
		let property = try propertyPattern(of: declaration)
		let associatedKey = associatedKeyToken(for: property)

		return [
			"private nonisolated(unsafe) static var \(associatedKey): Void?"
		]
	}
}

// Logic used by both macro implementations
extension ObservableDefaultMacro {
	/**
	Extracts the pattern (i.e. the name) of the attached property.
	*/
	private static func propertyPattern(
		of declaration: some SwiftSyntax.DeclSyntaxProtocol
	) throws(ObservableDefaultMacroError) -> TokenSyntax {
		// Must be attached to a property declaration.
		guard let variableDeclaration = declaration.as(VariableDeclSyntax.self) else {
			throw .notAttachedToProperty
		}

		// Must be attached to a variable property (i.e. `var` and not `let`).
		guard variableDeclaration.bindingSpecifier.tokenKind == .keyword(.var) else {
			throw .notAttachedToVariable
		}

		// Must be attached to a single property.
		guard variableDeclaration.bindings.count == 1, let binding = variableDeclaration.bindings.first else {
			throw .notAttachedToSingleProperty
		}

		// Must not provide an initializer for the property (i.e. not assign a value).
		guard binding.initializer == nil else {
			throw .attachedToPropertyWithInitializer
		}

		// Must not be attached to property with existing accessor block.
		guard binding.accessorBlock == nil else {
			throw .attachedToPropertyWithAccessorBlock
		}

		// Must use Identifier Pattern.
		// See https://swiftinit.org/docs/swift-syntax/swiftsyntax/identifierpatternsyntax
		guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
			throw .attachedToPropertyWithoutIdentifierProperty
		}

		return pattern
	}

	/**
	Extracts the expression used to define the Defaults.Key in the macro call.
	*/
	private static func keyExpression(
		of node: AttributeSyntax
	) throws(ObservableDefaultMacroError) -> ExprSyntax {
		// Must receive arguments
		guard let arguments = node.arguments else {
			throw .calledWithoutArguments
		}

		// Must be called with Labeled Expression.
		// See https://swiftinit.org/docs/swift-syntax/swiftsyntax/labeledexprlistsyntax
		guard let expressionList = arguments.as(LabeledExprListSyntax.self) else {
			throw .calledWithoutLabeledExpression
		}

		// Must only receive one argument.
		guard expressionList.count == 1, let expression = expressionList.first?.expression else {
			throw .calledWithMultipleArguments
		}

		return expression
	}

	/**
	 Generates the token to use as key for the associated object used to hold the UserDefaults observation.
	 */
	private static func associatedKeyToken(for property: TokenSyntax) -> TokenSyntax {
		"_objcAssociatedKey_\(property)"
	}
}

/**
Error handling for ``ObservableDefaultMacro``.
*/
public enum ObservableDefaultMacroError: Error {
	case notAttachedToProperty
	case notAttachedToVariable
	case notAttachedToSingleProperty
	case attachedToPropertyWithInitializer
	case attachedToPropertyWithAccessorBlock
	case attachedToPropertyWithoutIdentifierProperty
	case calledWithoutArguments
	case calledWithoutLabeledExpression
	case calledWithMultipleArguments
	case calledWithoutFunctionSyntax
	case calledWithoutKeyArgument
	case calledWithUnsupportedExpression
}

extension ObservableDefaultMacroError: CustomStringConvertible {
	public var description: String {
		switch self {
		case .notAttachedToProperty:
			"@ObservableDefault must be attached to a property."
		case .notAttachedToVariable:
			"@ObservableDefault must be attached to a `var` property."
		case .notAttachedToSingleProperty:
			"@ObservableDefault can only be attached to a single property."
		case .attachedToPropertyWithInitializer:
			"@ObservableDefault must not be attached with a property with a value assigned. To create set default value, provide it in the `Defaults.Key` definition."
		case .attachedToPropertyWithAccessorBlock:
			"@ObservableDefault must not be attached to a property with accessor block."
		case .attachedToPropertyWithoutIdentifierProperty:
			"@ObservableDefault could not identify the attached property."
		case .calledWithoutArguments,
			 .calledWithoutLabeledExpression,
			 .calledWithMultipleArguments,
			 .calledWithoutFunctionSyntax,
			 .calledWithoutKeyArgument,
			 .calledWithUnsupportedExpression:
			"@ObservableDefault must be called with (1) argument of type `Defaults.Key`"
		}
	}
}
