import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DefaultMacro: AccessorMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		// Must be attached to a property declaration.
		guard let variableDeclaration = declaration.as(VariableDeclSyntax.self) else {
			throw DefaultMacroError.notAttachedToProperty
		}

		// Must be attached to a variable property (i.e. `var` and not `let`).
		guard variableDeclaration.bindingSpecifier.tokenKind == .keyword(.var) else {
			throw DefaultMacroError.notAttachedToVariable
		}

		// Must be attached to a single property.
		guard variableDeclaration.bindings.count == 1, let binding = variableDeclaration.bindings.first else {
			throw DefaultMacroError.notAttachedToSingleProperty
		}

		// Must not provide an initializer for the property (i.e. not assign a value).
		guard binding.initializer == nil else {
			throw DefaultMacroError.attachedToPropertyWithInitializer
		}

		// Must not be attached to property with existing accessor block.
		guard binding.accessorBlock == nil else {
			throw DefaultMacroError.attachedToPropertyWithAccessorBlock
		}

		// Must use Identifier Pattern.
		// See https://swiftinit.org/docs/swift-syntax/swiftsyntax/identifierpatternsyntax
		guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
			throw DefaultMacroError.attachedToPropertyWithoutIdentifierProperty
		}

		// Must receive arguments
		guard let arguments = node.arguments else {
			throw DefaultMacroError.calledWithoutArguments
		}

		// Must be called with Labeled Expression.
		// See https://swiftinit.org/docs/swift-syntax/swiftsyntax/labeledexprlistsyntax
		guard let expressionList = arguments.as(LabeledExprListSyntax.self) else {
			throw DefaultMacroError.calledWithoutLabeledExpression
		}

		// Must only receive one argument.
		guard expressionList.count == 1, let expression = expressionList.first?.expression else {
			throw DefaultMacroError.calledWithMultipleArguments
		}

		return [
			#"""
			get {
				access(keyPath: \.\#(pattern))
				return Defaults[\#(expression)]
			}
			"""#,
			#"""
			set {
				withMutation(keyPath: \.\#(pattern)) {
					Defaults[\#(expression)] = newValue
				}
			}
			"""#
		]
	}
}

enum DefaultMacroError: Error {
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

extension DefaultMacroError: CustomStringConvertible {
	var description: String {
		switch self {
		case .notAttachedToProperty:
			"@Default must be attached to a property."
		case .notAttachedToVariable:
			"@Default must be attached to a `var` property."
		case .notAttachedToSingleProperty:
			"@Default can only be attached to a single property."
		case .attachedToPropertyWithInitializer:
			"@Default must not be attached with a property with a value assigned. To create set default value, provide it in the `Defaults.Key` definition."
		case .attachedToPropertyWithAccessorBlock:
			"@Default must not be attached to a property with accessor block."
		case .attachedToPropertyWithoutIdentifierProperty:
			"@Default could not identify the attached property."
		case .calledWithoutArguments,
			 .calledWithoutLabeledExpression,
			 .calledWithMultipleArguments,
			 .calledWithoutFunctionSyntax,
			 .calledWithoutKeyArgument,
			 .calledWithUnsupportedExpression:
			"@Default must be called with (1) argument of type `Defaults.Key`"
		}
	}
}
