//
//  Created by Georgiy Malyukov on 26.05.2018.
//  Copyright © 2022 Georgiy Malyukov. All rights reserved.
//
//  The MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

public enum CallStackParser {

    public typealias ParsedStackSymbol = (classname: String, method: String)

    /// Extracts classname and method from the specified stack symbol.
    /// - Parameters:
    ///   - stackSymbol: Specific item from `NSThread.callStackSymbols()`.
    ///   - includeImmediateParentClass: Appends immediate parent classname prefix to result when possible. Default is `true`.
    /// - Returns: Tuple containing the `(classname, method)` or `nil` if parsing fails.
    public static func parse(stackSymbol: String, includeImmediateParentClass: Bool = true) -> ParsedStackSymbol? {
        let replaced = stackSymbol.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
        let symbolsComponents = replaced.split(separator: " ")

        guard
            symbolsComponents.count >= 4,
            var packageClassAndMethodString = try? parseMangledSwiftSymbol(String(symbolsComponents[3])).description
        else {
            return nil
        }
        packageClassAndMethodString = packageClassAndMethodString.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression,
            range: nil
        )
        guard let packageComponent = packageClassAndMethodString.split(separator: " ").first else {
            return nil
        }

        let packageComponentString = String(packageComponent)
        let packageClassAndMethod = packageComponentString.split(separator: ".")
        let componentsCount = packageClassAndMethod.count

        guard componentsCount >= 2 else {
            return nil
        }
        let method = CallStackParser.cleanMethod(String(packageClassAndMethod[componentsCount - 1]))
        let currentClassname = packageClassAndMethod[componentsCount - 2]

        if includeImmediateParentClass && componentsCount >= 4 {
            let immediateClassname = packageClassAndMethod[componentsCount - 3]

            return ("\(immediateClassname).\(currentClassname)", method)
        }
        return (String(currentClassname), method)
    }

    /// Extracts **calling** classname and method from `NSThread.callStackSymbols()` if possible.
    /// - Parameter includeImmediateParentClass: Appends immediate parent classname prefix to result when possible. Default is `true`.
    /// - Returns: Tuple containing the `(classname, method)` or `nil` if parsing fails.
    public static func getCallingClassAndMethodInScope(includeImmediateParentClass: Bool = true) -> ParsedStackSymbol? {
        let stackSymbols = Thread.callStackSymbols

        guard stackSymbols.count >= 3 else {
            return nil
        }
        return CallStackParser.parse(stackSymbol: stackSymbols[2], includeImmediateParentClass: includeImmediateParentClass)
    }

    /// Extracts current classname and method from `NSThread.callStackSymbols()` if possible.
    /// - Parameter includeImmediateParentClass: Appends immediate parent classname prefix to result when possible. Default is `true`.
    /// - Returns: Tuple containing the `(classname, method)` or `nil` if parsing fails.
    public static func getCurrentClassAndMethodInScope(includeImmediateParentClass: Bool = true) -> ParsedStackSymbol? {
        let stackSymbols = Thread.callStackSymbols

        guard stackSymbols.count >= 2 else {
            return nil
        }
        return CallStackParser.parse(stackSymbol: stackSymbols[1], includeImmediateParentClass: includeImmediateParentClass)
    }

    // MARK: - Private Methods

    private static func cleanMethod(_ method: String) -> String {
        var result = method

        if result.count > 1 {
            let firstChar = result[result.startIndex]

            if firstChar == "(" {
                result = String(result[result.startIndex...])
            }
        }
        if !result.hasSuffix(")") {
            result += ")" // add closing bracket
        }
        return result
    }
}
