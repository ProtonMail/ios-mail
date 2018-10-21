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
        // if we have any significant Protector - wait for obtainMainKey(_:_:) method to be called
        guard !self.isProtectorActive(BioProtection.self),
            !self.isProtectorActive(PinProtection.self) else
        {
            return nil
        }
        
        // if we have NoneProtection active - get the key right ahead
        if let cypherText = NoneProtection.getCypherBits() {
            return try! NoneProtection().unlock(cypherBits: cypherText)
        }
        
        // otherwise there is no saved mainKey at all, so we should generate a new one with default protection
        return self.generateMainKeyWithDefaultProtection()
    }()
    
    static var shared = Keymaker()
    private let controlThread = DispatchQueue.global(qos: .utility)
    
    internal func wipeMainKey() {
        // TODO: remove additional keychain items of all protectors
        NoneProtection.removeCyphertextFromKeychain()
        BioProtection.removeCyphertextFromKeychain()
        PinProtection.removeCyphertextFromKeychain()
    }
    
    private func lockTheApp() {
        self.mainKey = nil
    }
    
    internal func obtainMainKey(with protector: ProtectionStrategy,
                                handler: @escaping (Key?)->Void)
    {
        // usually calling a method developers assume to get the callback on the same thread,
        // so for ease of use (and since most of callbacks turned out to work with UI)
        // we'll return to main thread explicitly here
        let isMainThread = Thread.current.isMainThread
        
        self.controlThread.async {
            guard self.mainKey == nil else {
                isMainThread ? DispatchQueue.main.async { handler(self.mainKey) } : handler(self.mainKey)
                return
            }
            
            guard let cypherBits = protector.getCypherBits() else {
                isMainThread ? DispatchQueue.main.async { handler(nil) } : handler(nil)
                return
            }

            let mainKeyBytes = try? protector.unlock(cypherBits: cypherBits)
            self.mainKey = mainKeyBytes
            isMainThread ? DispatchQueue.main.async { handler(self.mainKey) } : handler(self.mainKey)
        }
    }
    
    internal func activate(_ protector: ProtectionStrategy,
                           completion: @escaping (Bool)->Void)
    {
        let isMainThread = Thread.current.isMainThread
        self.controlThread.async {
            guard let mainKey = self.mainKey,
                let _ = try? protector.lock(value: mainKey),
                !(protector is NoneProtection) else
            {
                isMainThread ? DispatchQueue.main.async{ completion(false) } : completion(false)
                return
            }
            
            self.deactivate(NoneProtection())
            isMainThread ? DispatchQueue.main.async{ completion(true) } : completion(true)
        }
    }
    
    internal func isProtectorActive<T: ProtectionStrategy>(_ protectionType: T.Type) -> Bool {
        return protectionType.getCypherBits() != nil
    }
    
    @discardableResult internal func deactivate(_ protector: ProtectionStrategy) -> Bool {
        protector.removeCyphertextFromKeychain()
        
        // need to keep mainKey in keychain in case user switches off all the significant Protectors
        if !self.isProtectorActive(BioProtection.self), !self.isProtectorActive(PinProtection.self) {
            self.activate(NoneProtection(), completion: { _ in })
        }
        
        return true
    }
    
    func generateMainKeyWithDefaultProtection() -> Key {
        let mainKey = NoneProtection.generateRandomValue(length: 32)
        try! NoneProtection().lock(value: mainKey)
        return mainKey
    }
}
