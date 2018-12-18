//
//  ContactVOExtension.swift
//  ProtonMail - Created on 6/21/15.
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

extension ContactVO {
    
    /// ContactVO extension for check is contactVO contained by a array of Address
    ///
    /// - Parameter addresses: addresses check addresses
    /// - Returns: true | false
    func isDuplicated(_ addresses : [Address]) -> Bool {
        if addresses.map({ $0.email }).index(of: self.email) != nil {
            return true
        }
        return false
    }
    
    /**
     Checks if the current ContactVO is in the address list
    */
    func isDuplicatedWithContacts(_ addresses : [ContactPickerModelProtocol]) -> Bool {
        if addresses.map({
            if let contact = $0 as? ContactVO {
                return contact.email
            } else {
                return nil
            }
        }).index(of: self.email) != nil {
            return true
        }
        return false
    }
}
