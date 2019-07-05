//
//  UICKeyChainStore.swift
//  ProtonMail - Created on 05/07/2019.
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
import Security

// TODO: rename into something more reasonable
// TODO: write keychain-related logic

public class UICKeyChainStore {
    enum Accessibility {
        case afterFirstUnlockThisDeviceOnly
    }
    enum AccessControl {
        case userPresence
    }
    
    var accessibility: Accessibility
    var authenticationPolicy: AccessControl
    var accessGroup: String
    var service: String
    
    public init(service: String, accessGroup: String) {
        self.service = service
        self.accessGroup = accessGroup
        
        self.accessibility = .afterFirstUnlockThisDeviceOnly
        self.authenticationPolicy = .userPresence
    }
    
    internal func setAccessibility(_ accessibility: Accessibility, authenticationPolicy: AccessControl) {
        
    }
    
    public func set(_ intValue: Int, forKey key: String) {
        
    }
    public func setValue(_ intValue: Int, forKey key: String) {
        
    }
    
    public func setData(_ data: Data, forKey key: String) {
        
    }
    
    public func set(_ data: Data, forKey key: String) {
        
    }
    
    public func setString(_ string: String?, forKey key: String) {
        
    }
    
    public func data(forKey key: String) -> Data? {
        return nil
    }
    
    public static func data(forKey key: String) -> Data? {
        return nil
    }
    
    public func string(forKey key: String) -> String? {
        return nil
    }
    
    public func value(forKey key: String) -> Int? {
        return nil
    }
    
    public func intager(forKey key: String) -> Int? {
        return nil
    }
    
    public func removeItem(forKey key: String) {
        
    }
    
    public static func removeItem(forKey key: String) {
        
    }
}
