//
//  KeychainWrapper.swift
//  ProtonMail - Created on 7/17/17.
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
import Keymaker

final class KeychainWrapper: Keychain {
    private var prefix : String!
    private var service : String!
    private var group : String!
    
    public static var keychain = KeychainWrapper()
    
    init() {
        #if Enterprise
            prefix = "6UN54H93QT."
            group = prefix + "com.protonmail.protonmail"
            service = "com.protonmail"
        #else
            prefix = "2SB5Z68H26."
            group = prefix + "ch.protonmail.protonmail"
            service = "ch.protonmail"
        #endif
        
        super.init(service: service, accessGroup: group)
    }
}
