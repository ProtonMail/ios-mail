//
//  ProtectionStrategy.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Security
import UICKeyChainStore

public protocol ProtectionStrategy {
    var keychain: UICKeyChainStore { get }
    func lock(value: Keymaker.Key) throws
    func unlock(cypherBits: Data) throws -> Keymaker.Key
}
public extension ProtectionStrategy {
    static func saveCyphertext(_ cypher: Data, in keychain: UICKeyChainStore) {
        keychain.setData(cypher, forKey: String(describing: Self.self))
    }
    static func removeCyphertext(from keychain: UICKeyChainStore) {
        keychain.removeItem(forKey: String(describing: Self.self))
    }
    func removeCyphertextFromKeychain() {
        self.keychain.removeItem(forKey: String(describing: Self.self))
    }
    static func getCypherBits(from keychain: UICKeyChainStore) -> Data? {
        return keychain.data(forKey: String(describing: Self.self))
    }
    func getCypherBits() -> Data? {
        return self.keychain.data(forKey: String(describing: Self.self))
    }
    
    static func generateRandomValue(length: Int) -> Keymaker.Key {
        var newKey = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
}
