//
//  MessageAPI+SendType.swift
//  ProtonMail - Created on 4/12/18.
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


struct SendType : OptionSet {
    let rawValue: Int
    
    //address package one
    
    //internal email
    static let intl    = SendType(rawValue: 1 << 0)
    //encrypt outside
    static let eo      = SendType(rawValue: 1 << 1)
    //cleartext inline
    static let cinln   = SendType(rawValue: 1 << 2)
    //inline pgp
    static let inlnpgp = SendType(rawValue: 1 << 3)
    
    //address package two MIME
    
    //pgp mime
    static let pgpmime = SendType(rawValue: 1 << 4)
    //clear text mime
    static let cmime   = SendType(rawValue: 1 << 5)
    
}
