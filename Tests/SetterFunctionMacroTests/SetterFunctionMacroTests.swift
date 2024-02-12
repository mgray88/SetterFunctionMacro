import MacroTesting
import MacroToolkit
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
import SetterFunctionMacro

let testMacros: [String: Macro.Type] = [
    "setterFunction": SetterFunctionMacro.self,
]

final class SetterFunctionMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
            macros: testMacros
        ) {
            super.invokeTest()
        }
    }
    
    func testMacro() throws {
        assertMacro {
            """
            class Test {
                @setterFunction
                var text: String = ""
            }
            """
        } expansion: {
            """
            class Test {
                var text: String = ""

                @discardableResult
                func text(_ text: String) -> Self {
                    self.text = text
                    return self
                }
            }
            """
        }
    }

    func testFuncAccess() throws {
        assertMacro {
            """
            class Test {
                @setterFunction
                public var text: String = ""
            }
            """
        } expansion: {
            """
            class Test {
                public var text: String = ""

                @discardableResult
                public func text(_ text: String) -> Self {
                    self.text = text
                    return self
                }
            }
            """
        }
    }

    func testTypeRequired() throws {
        assertMacro {
            """
            class Test {
                @setterFunction
                var text = ""
            }
            """
        } diagnostics: {
            """
            class Test {
                @setterFunction
                ┬──────────────
                ╰─ 🛑 Due to macro limitations, the property type must be specified
                var text = ""
            }
            """
        }
    }

    func testConstant() throws {
        assertMacro {
            """
            struct Test {
                @setterFunction
                let text = "foo"
            }
            """
        } diagnostics: {
            """
            struct Test {
                @setterFunction
                ┬──────────────
                ╰─ 🛑 This macro cannot be used on a constant
                let text = "foo"
            }
            """
        }
    }

    func testNoSetter() throws {
        assertMacro {
            """
            struct Test {
                @setterFunction
                var text: String {
                    "foo"
                }
            }
            """
        } diagnostics: {
            """
            struct Test {
                @setterFunction
                ┬──────────────
                ╰─ 🛑 This macro cannot be used on computed properties
                var text: String {
                    "foo"
                }
            }
            """
        }
    }

    func testSetListeners() throws {
        assertMacro {
            """
            @setterFunction
            public var textAppearance: TextAppearance = .Default {
                didSet {
                    styled(with: textAppearance)
                }
            }
            """
        } expansion: {
            """
            public var textAppearance: TextAppearance = .Default {
                didSet {
                    styled(with: textAppearance)
                }
            }

            @discardableResult
            public func textAppearance(_ textAppearance: TextAppearance) -> Self {
                self.textAppearance = textAppearance
                return self
            }
            """
        }
    }
}
