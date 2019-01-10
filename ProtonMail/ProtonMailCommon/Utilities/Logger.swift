//
//  Logger.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
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


public class PMLog {
    
    static func D(nstring message: NSString, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(_ message: String, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(any message: Any, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(api error: NSError, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) :")
        print("Domain = " + error.domain)
        print("LocalizedDesc = " + error.localizedDescription)
        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
            print(detail)
        }
        if let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? Data,
            let resObj = String(data: data, encoding: .utf8) {
            print("ErrorDetails = " + resObj)
        }
        print("")
        #endif
    }
}
