//
//  Keymaker.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 13/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//
//  There is a building. Inside this building there is a level
//  where no elevator can go, and no stair can reach. This level
//  is filled with doors. These doors lead to many places. Hidden
//  places. But one door is special. One door leads to the source.
//

import Foundation

var keymaker = Keymaker.shared
class Keymaker: NSObject {
    typealias Key = Array<UInt8>
    
    private(set) lazy var mainKey: Key? = {
        let protector = NoneProtection()
        guard let cypherText = protector.getCypherBits(),
            let clearText = try? protector.unlock(cypherBits: cypherText) else
        {
            return nil
        }
        return clearText
    }()
    
    static var shared = Keymaker()
    private let controlThread = DispatchQueue.global(qos: .utility)
    
    internal func wipeMainKey() {
        // TODO: remove keychain items of all protectors
        NoneProtection().removeCyphertextFromKeychain()
    }
    
    private func lockTheApp() {
        // TODO: check that we have protectors other than NoneProtector
        self.mainKey = nil
    }
    
    internal func obtainMainKey(with protector: ProtectionStrategy) -> Key? {
        guard self.mainKey == nil else {
            return self.mainKey
        }
        
        guard let cypherBits = protector.getCypherBits() else {
            return nil
        }

        let mainKeyBytes = try? protector.unlock(cypherBits: cypherBits)
        self.mainKey = mainKeyBytes // FIXME: should we do that if the unlock failed?
        return mainKeyBytes
    }
    
    
    internal func isProtectorActive(_ protectionType: Any.Type) -> Bool { // FIXME: rewrite with generics and static methods
        if protectionType == BioProtection.self {
            return BioProtection(keychainGroup: sharedKeychain.group).getCypherBits() != nil
        }
        if protectionType == NoneProtection.self {
            return NoneProtection().getCypherBits() != nil
        }
        if protectionType == PinProtection.self {
            return PinProtection(pin: "").getCypherBits() != nil // empty string here is on purpose: we will not check this pin ever
        }
        return false
    }
    
    @discardableResult internal func activate(_ protector: ProtectionStrategy) -> Bool {
        guard let mainKey = self.mainKey else {
            return false
        }
        
        guard let _ = try? protector.lock(value: mainKey),
            !(protector is NoneProtection) else
        {
            return false
        }
        self.deactivate(NoneProtection())
        return true
    }
    
    @discardableResult internal func deactivate(_ protector: ProtectionStrategy) -> Bool {
        protector.removeCyphertextFromKeychain()
        return true // FIXME: check if any other protectors are active, if not - activate NoneProtection
    }
    
    func generateNoneProtectedMainKey() {
        let protector = NoneProtection()
        let mainKey = protector.generateRandomValue(length: 32)
        try! protector.lock(value: mainKey)
        self.mainKey = mainKey
    }
}
