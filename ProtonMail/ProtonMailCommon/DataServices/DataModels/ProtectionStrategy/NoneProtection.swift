//
//  NoneProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import UICKeyChainStore

struct NoneProtection: ProtectionStrategy {
    func lock(value: Keymaker.Key) throws {
        NoneProtection.saveCyphertextInKeychain(Data(bytes: value))
    }
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key {
        return cypherBits.bytes
    }
}

extension NoneProtection {
    static var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
    
    var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
}
