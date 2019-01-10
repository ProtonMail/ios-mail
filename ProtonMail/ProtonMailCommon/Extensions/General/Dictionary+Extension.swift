//
//  DictionaryExtension.swift
//  ProtonMail - Created on 7/2/15.
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

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any { //email name
    public func getDisplayName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            let name = self[key] as? String ?? ""
            if !name.isEmpty {
                return name
            }
        }
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    public func getAddress() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    public func getName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
}

