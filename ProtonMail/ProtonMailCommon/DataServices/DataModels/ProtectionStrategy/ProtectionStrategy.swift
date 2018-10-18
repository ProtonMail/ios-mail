//
//  ProtectionStrategy.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Security

protocol ProtectionStrategy {
    func lock(value: Keymaker.Key) throws
    func unlock(cypherBits: Data) throws -> Keymaker.Key
    
    func getCypherBits() -> Data?
}
extension ProtectionStrategy {
    func saveCyphertextInKeychain(_ cypher: Data) {
        sharedKeychain.keychain()?.setData(cypher, forKey: String(describing: Self.self))
    }
    func removeCyphertextFromKeychain() {
        sharedKeychain.keychain()?.removeItem(forKey: String(describing: Self.self))
    }
    func getCypherBits() -> Data? {
        return sharedKeychain.keychain()?.data(forKey: String(describing: Self.self))
    }
    
    func generateRandomValue(length: Int) -> Array<UInt8> {
        var newKey = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
    
//------------------------ MOCK --------------------------
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key  {
        // TODO: implement in all the conformers
        fatalError()
        /*
         switch track {
         case .pin(let userInputPin):
         // let user enter PIN
         // pass handler further
         break
         
         case .bio:
         // talk to secure enclave
         // call handler()
         break
         
         case .none:
         // main key is stored in Keychain cleartext
         // call handler()
         break
         
         case .bioAndPin: break // can not happen in real life: two different UIs
         }
         */
    }
}
