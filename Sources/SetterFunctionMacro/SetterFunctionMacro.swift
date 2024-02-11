import MacroToolkit
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum SetterFunctionError: CustomStringConvertible, Error {
    case notAVariable
    case notSettable
    case complexIdentifier
    case typeMissing
    case computed

    public var description: String {
        return switch self {
        case .notAVariable:
            "This macro can only be applied to variables"

        case .notSettable:
            "This macro cannot be used on a constant"

        case .complexIdentifier:
            "The property must have a simple identifier"

        case .typeMissing:
            "Due to macro limitations, the property type must be specified"

        case .computed:
            "This macro cannot be used on computed properties"
        }
    }
}

/// Implementation of the `setterFunction` macro, which is applied to class
/// properties to create a chainable setter function:
///
///     @setterFunction
///     var someText: String = ""
///
///  will expand to
///
///     var someText: String = ""
///     
///     @discardableResult
///     func someText(_ someText: String) -> Self {
///         self.someText = someText
///         return self
///     }
///
public struct SetterFunctionMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let decl = declaration.as(VariableDeclSyntax.self) else {
            throw SetterFunctionError.notAVariable
        }

        guard decl.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw SetterFunctionError.notSettable
        }

        let variable = Variable(decl)
        return try variable.bindings
            .map { binding in
                guard let identifier = binding.identifier else {
                    throw SetterFunctionError.complexIdentifier
                }
                
                guard let type = binding.type else {
                    throw SetterFunctionError.typeMissing
                }

                if !binding.accessors.isEmpty {
                    guard binding.accessors.contains(where: { accessor in
                        accessor.accessorSpecifier.tokenKind == .keyword(.set)
                    }) else {
                        throw SetterFunctionError.computed
                    }
                }

                let access = decl.modifiers
                    .first(where: { $0.name.tokenKind == .keyword(.public) })
                    .map { $0.name.text + " " }

                var function = try FunctionDeclSyntax(
                    "\(raw: access ?? "")func \(raw: identifier)(_ text: \(raw: type.normalizedDescription)) -> Self"
                ) {
                    "self.\(raw: identifier) = \(raw: identifier)"
                    "return self"
                }.withLeadingNewline()

                function.attributes.append(.attribute("@discardableResult"))
                return DeclSyntax(function)
            }
    }
}

extension SyntaxStringInterpolation {
    // It would be nice for SwiftSyntaxBuilder to provide this out-of-the-box.
    mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
        if let node {
            appendInterpolation(node)
        }
    }
}

@main
struct SetterFunctionMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SetterFunctionMacro.self,
    ]
}
