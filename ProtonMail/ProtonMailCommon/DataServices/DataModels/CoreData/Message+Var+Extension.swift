//
//  Message+Var+Extension.swift
//  ProtonMail - Created on 11/6/18.
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


extension Message {
    
    var isForwarded : Bool {
        get {
            return self.flag.contains(.forwarded)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.forwarded)
            } else {
                flag.insert(.forwarded)
            }
            self.flag = flag
        }
    }
    
    var isReplied : Bool {
        get {
            return self.flag.contains(.replied)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.replied)
            } else {
                flag.insert(.replied)
            }
            self.flag = flag
        }
    }
    
    var isRepliedAll : Bool {
        get {
            return self.flag.contains(.repliedAll)
        }
        set {
            var flag = self.flag
            if newValue {
                flag.remove(.repliedAll)
            } else {
                flag.insert(.repliedAll)
            }
            self.flag = flag
        }
    }
}
