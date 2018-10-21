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

protocol ProtectionStrategy {
    static var keychain: UICKeyChainStore { get }
    var keychain: UICKeyChainStore { get }
    func lock(value: Keymaker.Key) throws
    func unlock(cypherBits: Data) throws -> Keymaker.Key
}
extension ProtectionStrategy {
    static func saveCyphertextInKeychain(_ cypher: Data) {
        self.keychain.setData(cypher, forKey: String(describing: Self.self))
    }
    static func removeCyphertextFromKeychain() {
        self.keychain.removeItem(forKey: String(describing: Self.self))
    }
    func removeCyphertextFromKeychain() {
        Self.removeCyphertextFromKeychain()
    }
    static func getCypherBits() -> Data? {
        return self.keychain.data(forKey: String(describing: Self.self))
    }
    func getCypherBits() -> Data? {
        return Self.getCypherBits()
    }
    
    static func generateRandomValue(length: Int) -> Array<UInt8> {
        var newKey = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
}
