//
//  CallStackAnalyser.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.01.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation

class CallStackParser {

    private static func cleanMethod(method: (String)) -> String {
        var result = method
        if result.count > 1 {
            let firstChar: Character = result[result.startIndex]
            if firstChar == "(" {
                result = String(result[result.startIndex...])
            }
        }
        if !result.hasSuffix(")") {
            result += ")" // add closing bracket
        }
        return result
    }

    /**
     Takes a specific item from 'NSThread.callStackSymbols()' and returns the class and method call contained within.
     
     - Parameter stackSymbol: a specific item from 'NSThread.callStackSymbols()'
     - Parameter includeImmediateParentClass: Whether or not to include the parent class in an innerclass situation.
     
     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    static func classAndMethodForStackSymbol(_ stackSymbol: String, includeImmediateParentClass: Bool? = false) -> (String, String)? {
        let replaced = stackSymbol.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression, range: nil)
        let components = replaced.split(separator: " ")
        if components.count >= 4 {
            guard var packageClassAndMethodStr = try? parseMangledSwiftSymbol(String(components[3])).description else { return nil }
            packageClassAndMethodStr = packageClassAndMethodStr.replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression,
                range: nil
            )
            let packageComponent = String(packageClassAndMethodStr.split(separator: " ").first!)
            let packageClassAndMethod = packageComponent.split(separator: ".")
            let numberOfComponents = packageClassAndMethod.count
            if numberOfComponents >= 2 {
                let method = cleanUpMethod(String(packageClassAndMethod[numberOfComponents-1]))
                if includeImmediateParentClass != nil {
                    if includeImmediateParentClass == true && numberOfComponents == 3 {
                        return ("\(packageClassAndMethod[numberOfComponents-2])", method)
                    }
                    if includeImmediateParentClass == true && numberOfComponents == 4 {
                        return ("\(packageClassAndMethod[numberOfComponents-3]).\(packageClassAndMethod[numberOfComponents-2])", method)
                    }
                    if includeImmediateParentClass == true && numberOfComponents == 5 {
                        return ("\(packageClassAndMethod[numberOfComponents-4]).\(packageClassAndMethod[numberOfComponents-3]).\(packageClassAndMethod[numberOfComponents-2])", method)
                    }
                    if includeImmediateParentClass == true && numberOfComponents == 6 {
                        return ("\(packageClassAndMethod[numberOfComponents-5]).\(packageClassAndMethod[numberOfComponents-4]).\(packageClassAndMethod[numberOfComponents-3])", cleanUpMethod("\(packageClassAndMethod[numberOfComponents-2])"))
                    }
                }
                return (String(packageClassAndMethod[numberOfComponents-2]), method)
            }
        }
        return nil
    }

    static private func cleanUpMethod(_ method: String) -> String {
        return CallStackParser.cleanMethod(method: method).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "Swift", with: "")
    }

    /**
     Analyses the 'NSThread.callStackSymbols()' and returns the calling class and method in the scope of the caller.
     
     - Parameter includeImmediateParentClass: Whether or not to include the parent class in an innerclass situation.
     
     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    static func getCallingClassAndMethodInScope(includeImmediateParentClass: Bool? = true) -> (String, String) {
        let stackSymbols = Thread.callStackSymbols
        for trace in stackSymbols {
            if trace.contains("ProtonMailUITests") && !trace.contains("CallStackParser") && !trace.contains("UiElement") {
                return CallStackParser.classAndMethodForStackSymbol(trace, includeImmediateParentClass: includeImmediateParentClass) ?? ("", "")
            }
        }
        return ("", "")
    }

    /**
     Analyses the 'NSThread.callStackSymbols()' and returns the current class and method in the scope of the caller.
     
     - Parameter includeImmediateParentClass: Whether or not to include the parent class in an innerclass situation.
     
     - Returns: a tuple containing the (class,method) or nil if it could not be parsed
     */
    static func getThisClassAndMethodInScope(includeImmediateParentClass: Bool? = false) -> (String, String)? {
        let stackSymbols = Thread.callStackSymbols
        if stackSymbols.count >= 8 {
            return CallStackParser.classAndMethodForStackSymbol(stackSymbols[1], includeImmediateParentClass: includeImmediateParentClass)
        }
        return nil
    }
}

extension String {

    subscript (offset: Int) -> Character {
        return self[index(startIndex, offsetBy: offset)]
    }

    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }

    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }

    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }

    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }

    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }

}

extension Substring {

    subscript (offset: Int) -> Character {
        return self[index(startIndex, offsetBy: offset)]
    }

    subscript (bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ..< end]
    }

    subscript (bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[start ... end]
    }

    subscript (bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        return self[start ... end]
    }

    subscript (bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ... end]
    }

    subscript (bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return self[startIndex ..< end]
    }

}
