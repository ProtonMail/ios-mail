//
//  UICKeyChainStore.swift
//  ProtonMail - Created on 05/07/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    
import Foundation
import Security

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
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            queryForSearch[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        let codeExisting = SecItemCopyMatching(queryForSearch as CFDictionary, nil)
        
        // update
        guard codeExisting == errSecItemNotFound else {
            var updateAttributes: [String: AnyObject] = [
                kSecAttrSynchronizable as String: NSNumber(value: false),
                kSecValueData as String: value as AnyObject
            ]
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
                updateAttributes[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
            }
            self.injectAccessControlAttributes(into: &updateAttributes)
            
            let codeUpdate = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            assert(codeUpdate == noErr, "Error updating \(key) to Keychain: \(codeUpdate)")
            return codeUpdate == noErr
        }
        
        // add new
        var newAttributes = query
        newAttributes[kSecAttrSynchronizable as String] = NSNumber(value: false)
        newAttributes[kSecValueData as String] = value as AnyObject
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            newAttributes[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
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
        var query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        
        let code = SecItemDelete(query as CFDictionary)
        
        guard code == noErr else {
            return false
        }
        
        return true
    }
}
