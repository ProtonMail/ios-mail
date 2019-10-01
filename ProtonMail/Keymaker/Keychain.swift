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

// TODO: write keychain-related logic

open class Keychain {
    internal enum Accessibility {
        case afterFirstUnlockThisDeviceOnly
        
        var cfString: CFString {
            switch self {
                case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }
    internal enum AccessControl {
        case none, userPresence
        
        var flags: SecAccessControlCreateFlags? {
            switch self {
            case .userPresence: return [.userPresence]
            case .none: return nil
            }
        }
    }
    
    internal var accessibility: Accessibility
    internal var authenticationPolicy: AccessControl
    internal let accessGroup: String
    internal let service: String
    
    internal func switchAccessibilitySettings(_ accessibility: Accessibility, authenticationPolicy: AccessControl) {
        self.accessibility = accessibility
        self.authenticationPolicy = authenticationPolicy
    }
    
    public init(service: String, accessGroup: String) {
        self.service = service
        self.accessGroup = accessGroup
        
        self.accessibility = .afterFirstUnlockThisDeviceOnly
        self.authenticationPolicy = .none
    }
    
    public func set(_ data: Data, forKey key: String) {
        self.add(data: data, forKey: key)
    }
    
    public func set(_ string: String, forKey key: String) {
        self.add(data: string.data(using: .utf8)!, forKey: key)
    }
    
    public func data(forKey key: String) -> Data? {
        return self.getData(forKey: key)
    }
    
    public func string(forKey key: String) -> String? {
        guard let data = self.getData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func remove(forKey key: String) {
        _ = self.remove(key)
    }
    
    
    // Private - internal for unit tests
    
    internal func getData(forKey key: String) -> Data? {
        var query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        if let auth = self.authenticationPolicy.flags,
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, self.accessibility.cfString, auth, nil)
        {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        var result: AnyObject?
        let code = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        guard code == noErr, let data = result as? Data else {
            print("Error loading item \(key) from Keychain: \(code)")
            return nil
        }
        
        return data
    }
    
    @discardableResult
    internal func remove(_ key: String) -> Bool {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        let code = SecItemDelete(query as CFDictionary)
        
        guard code == noErr else {
            print("Error deleting item \(key) from Keychain: \(code)")
            return false
        }
        
        return true
    }
    
    @discardableResult
    internal func add(data value: Data, forKey key: String) -> Bool {
        // search for existing
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        var queryForSearch = query
        queryForSearch[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        let codeExisting = SecItemCopyMatching(queryForSearch as CFDictionary, nil)
        
        // update
        guard codeExisting == errSecItemNotFound else {
            var updateAttributes: [String: AnyObject] = [
                kSecAttrSynchronizable as String: NSNumber(booleanLiteral: false),
                kSecValueData as String: value as AnyObject
            ]
            self.injectAccessControlAttributes(into: &updateAttributes)
            
            let codeUpdate = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            assert(codeUpdate == noErr, "Error updating \(key) to Keychain: \(codeUpdate)")
            return codeUpdate == noErr
        }
        
        // add new
        var newAttributes = query
        newAttributes[kSecAttrSynchronizable as String] = NSNumber(booleanLiteral: false)
        newAttributes[kSecValueData as String] = value as AnyObject
        self.injectAccessControlAttributes(into: &newAttributes)

        let code = SecItemAdd(newAttributes as CFDictionary, nil)
        assert(code == noErr, "Error saving \(key) to Keychain: \(code)")
        return code == noErr
    }
    
    private func injectAccessControlAttributes(into attributes: inout [String: AnyObject]) {
        if let auth = self.authenticationPolicy.flags,
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, self.accessibility.cfString, auth, nil)
        {
            attributes[kSecAttrAccessControl as String] = accessControl
        } else {
            attributes[kSecAttrAccessible as String] = self.accessibility.cfString
        }
    }
    
    @discardableResult
    public func removeEverything() -> Bool { 
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        let code = SecItemDelete(query as CFDictionary)
        
        guard code == noErr else {
            print("Error deleting from Keychain: \(code)")
            return false
        }
        
        return true
    }
}
