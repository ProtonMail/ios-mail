//
//  String+Html+Ext.swift
//  ProtonMail - Created on 5/8/15.
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

extension String {
    /// A string with the ' characters in it escaped.
    /// Used when passing a string into JavaScript, so the string is not completed too soon
    /// refer: https://github.com/cjwirth/RichEditorView
    var escaped: String {
        let unicode = self.unicodeScalars
        var newString = ""
        for char in unicode {
            if char.value == 39 || // 39 == ' in ASCII
                char.value < 9 ||  // 9 == horizontal tab in ASCII
                (char.value > 9 && char.value < 32) // < 32 == special characters in ASCII
            {
                let escaped = char.escaped(asASCII: true)
                newString.append(escaped)
            } else {
                newString.append(String(char))
            }
        }
        return newString
    }
}
