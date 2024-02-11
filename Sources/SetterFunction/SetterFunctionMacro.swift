// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that creates a chainable setter function for a given property
/// in a class
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
@attached(peer, names: arbitrary)
public macro setterFunction() = #externalMacro(module: "SetterFunctionMacro", type: "SetterFunctionMacro")
