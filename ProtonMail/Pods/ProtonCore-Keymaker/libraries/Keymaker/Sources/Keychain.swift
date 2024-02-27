//
//  UICKeyChainStore.swift
//  ProtonCore-ProtonCore-Keymaker - Created on 05/07/2019.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Security

public protocol SecItemMethodsProvider {
    func SecItemCopyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func SecItemAdd(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func SecItemUpdate(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    func SecItemDelete(_ query: CFDictionary) -> OSStatus
}

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

    public enum AccessError: LocalizedError {
        case readFailed(key: String, error: OSStatus)
        case writeFailed(key: String, error: OSStatus)
        case updateFailed(key: String, error: OSStatus)
        case deleteFailed(key: String, error: OSStatus)

        public var errorDescription: String? {
            switch self {
            case let .readFailed(key, code):
                return "Keychain.AccessError.readFailed(\(key), \(code))"
            case let .writeFailed(key, code):
                return "Keychain.AccessError.writeFailed(\(key), \(code))"
            case let .updateFailed(key, code):
                return "Keychain.AccessError.updateFailed(\(key), \(code))"
            case let .deleteFailed(key, code):
                return "Keychain.AccessError.deleteFailed(\(key), \(code))"
            }
        }
    }

    internal var accessibility: Accessibility
    internal var authenticationPolicy: AccessControl
    internal let accessGroup: String
    internal let service: String
    internal let keychainQueue = DispatchQueue(label: "me.proton.account.keychain.queue", attributes: .concurrent)

    private let secItemMethodsProvider: SecItemMethodsProvider

    internal func switchAccessibilitySettings(_ accessibility: Accessibility, authenticationPolicy: AccessControl) {
        self.accessibility = accessibility
        self.authenticationPolicy = authenticationPolicy
    }

    public init(service: String, accessGroup: String, secItemMethodsProvider: SecItemMethodsProvider? = nil) {
        self.service = service
        self.accessGroup = accessGroup

        self.secItemMethodsProvider = secItemMethodsProvider ?? SystemSecurityFrameworkSecItemMethodsProvider.instance

        self.accessibility = .afterFirstUnlockThisDeviceOnly
        self.authenticationPolicy = .none
    }

    /// Adds or updates the value in the keychain.
    ///
    /// This method returns regardless of whether:
    /// * the value was successfully added or updated in the keychain
    /// * keychain update failed because of the keychain access error
    /// - Parameters:
    ///   - data: data to be added / updated in keychain
    ///   - key: key under which the data should be added / updated
    @available(*, deprecated, message: "Please use the throwing alternative: setOrError(:forKey:) and handle the error")
    public func set(_ data: Data, forKey key: String, attributes: [CFString: Any]? = nil) {
       _ = self.add(data: data, forKey: key, attributes: attributes)
    }

    /// Adds or updates the value in the keychain.
    ///
    /// This method returns regardless of whether:
    /// * the value was successfully added or updated in the keychain
    /// * keychain update failed because of the keychain access error
    /// - Parameters:
    ///   - string: string to be added / updated in keychain
    ///   - key: key under which the string should be added / updated
    @available(*, deprecated, message: "Please use the throwing alternative: setOrError(:forKey:) and handle the error")
    public func set(_ string: String, forKey key: String, attributes: [CFString: Any]? = nil) {
        _ = self.add(data: string.data(using: .utf8)!, forKey: key, attributes: attributes)
    }

    /// Adds or updates the value in the keychain.
    ///
    /// This method:
    /// * returns if the value was successfully added or updated in the keychain
    /// * throws the error if keychain update failed because of the keychain access error
    /// - Parameters:
    ///   - data: data to be added / updated in keychain
    ///   - key: key under which the data should be added / updated
    public func setOrError(_ data: Data, forKey key: String,  attributes: [CFString: Any]? = nil) throws {
        try self.addOrError(data: data, forKey: key, attributes: attributes)
    }

    /// Adds or updates the value in the keychain.
    ///
    /// This method:
    /// * returns if the value was successfully added or updated in the keychain
    /// * throws the error if keychain update failed because of the keychain access error
    /// - Parameters:
    ///   - string: string to be added / updated in keychain
    ///   - key: key under which the string should be added / updated
    public func setOrError(_ string: String, forKey key: String, attributes: [CFString: Any]? = nil) throws {
        try self.addOrError(data: string.data(using: .utf8)!, forKey: key, attributes: attributes)
    }

    /// Fetches the value from the keychain.
    ///
    /// This method:
    /// * returns the value if it was found in the keychain,
    /// * returns nil if there was no value in the keychain OR the keychain read failed because of the keychain access
    /// - Parameters:
    ///   - forKey: key under which the value is stored in keychain
    @available(*, deprecated, message: "Please use the throwing alternative: dataOrError(forKey:) and handle the error")
    public func data(forKey key: String, attributes: [CFString: Any]? = nil) -> Data? {
        return self.getData(forKey: key, attributes: attributes)
    }

    /// Fetches the value from the keychain.
    ///
    /// This method:
    /// * returns the value if it was found in the keychain,
    /// * returns nil if there was no value in the keychain OR the keychain read failed because of the keychain access
    /// - Parameters:
    ///   - forKey: key under which the value is stored in keychain
    @available(*, deprecated, message: "Please use the throwing alternative: stringOrError(forKey:) and handle the error")
    public func string(forKey key: String, attributes: [CFString: Any]? = nil) -> String? {
        guard let data = self.getData(forKey: key, attributes: attributes) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Fetches the value from the keychain.
    ///
    /// This method:
    /// * returns the value if it was found in the keychain,
    /// * returns nil if there was no value in the keychain,
    /// * throws the error if keychain read failed because of the keychain access error
    /// - Parameters:
    ///   - forKey: key under which the value is stored in keychain
    public func dataOrError(forKey key: String, attributes: [CFString: Any]? = nil) throws -> Data? {
        try self.getDataOrError(forKey: key, attributes: attributes)
    }

    /// Fetches the value from the keychain.
    ///
    /// This method:
    /// * returns the value if it was found in the keychain,
    /// * returns nil if there was no value in the keychain,
    /// * throws the error if keychain read failed because of the keychain access error
    /// - Parameters:
    ///   - forKey: key under which the value is stored in keychain
    public func stringOrError(forKey key: String, attributes: [CFString: Any]? = nil) throws -> String? {
        guard let data = try self.getDataOrError(forKey: key, attributes: attributes) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Removes the value from the keychain.
    ///
    /// This method returns regardless of whether:
    /// * keychain delete succeeded
    /// * there was nothing to remove
    /// * keychain delete failed because of the keychain access error
    /// - Parameters:
    ///   - forKey: key under which the value should be removed from the keychain
    @available(*, deprecated, message: "Please use the throwing alternative: removeOrError(forKey:) and handle the error")
    public func remove(forKey key: String) {
        _ = self.remove(key)
    }

    /// Removes the value from the keychain.
    ///
    /// This method:
    /// * returns if keychain delete succeeds or if there was nothing to remove,
    /// * throws if keychain delete failed because of the keychain access error
    /// - Parameters:
    ///   - forKey: key under which the value should be removed from the keychain
    public func removeOrError(forKey key: String) throws {
        try self.removeOrError(key)
    }

    // Private - internal for unit tests
    @available(*, deprecated, message: "Please use the throwing alternative: getDataOrError(forKey:) and handle the error")
    internal func getData(forKey key: String,  attributes: [CFString: Any]? = nil) -> Data? {
        try? getDataOrError(forKey: key, attributes: attributes)
    }

    internal func getDataOrError(forKey key: String, attributes: [CFString: Any]? = nil) throws -> Data? {
        var query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        if #available(macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }

        if let auth = self.authenticationPolicy.flags,
            let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, self.accessibility.cfString, auth, nil)
        {
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        if let attributes {
            for(key, value) in attributes {
                query[key as String] = value as AnyObject
            }
        }

        let secItem = secItemMethodsProvider

        return try keychainQueue.sync {
            var result: AnyObject?
            let code = withUnsafeMutablePointer(to: &result) {
                secItem.SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }

            guard code == noErr, let data = result as? Data else {
                if code == errSecItemNotFound {
                    // data not found in the keychain, return nil
                    return nil
                } else {
                    // reading from keychain errored out, return the error
                    throw Keychain.AccessError.readFailed(key: key, error: code)
                }
            }

            return data
        }
    }

    @discardableResult
    @available(*, deprecated, message: "Please use the throwing alternative: removeOrError(:) and handle the error")
    internal func remove(_ key: String) -> Bool {
        do {
            try removeOrError(key)
            return true
        } catch {
            return false
        }
    }

    internal func removeOrError(_ key: String) throws {
        var query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        if #available(macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }

        let secItem = secItemMethodsProvider

        return try keychainQueue.sync(flags: .barrier) {
            let code = secItem.SecItemDelete(query as CFDictionary)

            guard code == noErr || code == errSecItemNotFound else {
                throw Keychain.AccessError.deleteFailed(key: key, error: code)
            }
        }
    }

    @available(*, deprecated, message: "Please use the throwing alternative: addOrError(data:forKey:) and handle the error")
    internal func add(data value: Data, forKey key: String, attributes: [CFString: Any]? = nil) -> Bool {
        do {
            try addOrError(data: value, forKey: key, attributes: attributes)
            return true
        } catch {
            return false
        }
    }

    internal func addOrError(data value: Data, forKey key: String, attributes: [CFString: Any]? = nil) throws {
        // search for existing
        var query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service as AnyObject,
            kSecAttrAccount as String: key as AnyObject,
            kSecAttrAccessGroup as String: self.accessGroup as AnyObject,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        if #available(macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }
        
        if let attributes {
            for(key, value) in attributes {
                query[key as String] = value as AnyObject
            }
        }

        var queryForSearch = query
        if #unavailable(macOS 11.0, iOS 15.0, macCatalyst 15.0) {
            queryForSearch[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        }

        let secItem = secItemMethodsProvider

        return try keychainQueue.sync(flags: .barrier) {
            let codeExisting = secItem.SecItemCopyMatching(queryForSearch as CFDictionary, nil)

            // update
            guard codeExisting == errSecItemNotFound else {
                var updateAttributes: [String: AnyObject] = [
                    kSecAttrSynchronizable as String: NSNumber(value: false),
                    kSecValueData as String: value as AnyObject
                ]
                self.injectAccessControlAttributes(into: &updateAttributes)

                let codeUpdate = secItem.SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
                guard codeUpdate == noErr else {
                    throw Keychain.AccessError.updateFailed(key: key, error: codeUpdate)
                }
                return
            }

            // add new
            var newAttributes = query
            newAttributes[kSecAttrSynchronizable as String] = NSNumber(value: false)
            newAttributes[kSecValueData as String] = value as AnyObject
            self.injectAccessControlAttributes(into: &newAttributes)

            let code = secItem.SecItemAdd(newAttributes as CFDictionary, nil)
            guard code == noErr else {
                throw Keychain.AccessError.writeFailed(key: key, error: code)
            }
            return
        }
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
        if #available(macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.0, *) {
            query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        }

        let secItem = secItemMethodsProvider

        return keychainQueue.sync(flags: .barrier) {
            let code = secItem.SecItemDelete(query as CFDictionary)

            guard code == noErr || code == errSecItemNotFound else {
                return false
            }

            return true
        }
    }
}

private enum SystemSecurityFrameworkSecItemMethodsProvider: SecItemMethodsProvider {

    case instance

    func SecItemCopyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        Security.SecItemCopyMatching(query, result)
    }

    func SecItemAdd(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        Security.SecItemAdd(attributes, result)
    }

    func SecItemUpdate(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
        Security.SecItemUpdate(query, attributesToUpdate)
    }

    func SecItemDelete(_ query: CFDictionary) -> OSStatus {
        Security.SecItemDelete(query)
    }
}
