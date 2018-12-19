//
//  NoneProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import UICKeyChainStore

public struct NoneProtection: ProtectionStrategy {
    public let keychain: UICKeyChainStore
    
    public init(keychain: UICKeyChainStore) {
        self.keychain = keychain
    }
    
    public func lock(value: Keymaker.Key) throws {
        NoneProtection.saveCyphertext(Data(bytes: value), in: self.keychain)
    }
    
    public func unlock(cypherBits: Data) throws -> Keymaker.Key {
        return cypherBits
    }
}

