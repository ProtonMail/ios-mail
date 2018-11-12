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
import UICKeyChainStore

public class Keymaker: NSObject {
    public static let requestMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".requestMainKey")
    public static let obtainedMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".obtainedMainKey")
    public typealias Key = Array<UInt8>
    
    private var autolocker: Autolocker?
    private let keychain: UICKeyChainStore
    public init(autolocker: Autolocker, keychain: UICKeyChainStore) {
        self.autolocker = autolocker
        self.keychain = keychain
    }
    
    // stored in-memory value
    private var _mainKey: Key? {
        didSet {
            if _mainKey != nil {
                self.autolocker?.autolockCountdownStart = nil
            }
        }
    }
    
    // accessor for stored value; if stored value is nill - calls provokeMainKeyObtention() method
    public var mainKey: Key? {
        if self.autolocker?.shouldAutolockNow() == true {
            self._mainKey = nil
        }
        if self._mainKey == nil {
            self._mainKey = self.provokeMainKeyObtention()
        }
        return self._mainKey
    }
    
    // Try to get main key from storage if it exists, otherwise create one.
    // if there is any significant Protection active - post message that obtainMainKey(_:_:) is needed
    private func provokeMainKeyObtention() -> Key? {
        // if we have any significant Protector - wait for obtainMainKey(_:_:) method to be called
        guard !self.isProtectorActive(BioProtection.self),
            !self.isProtectorActive(PinProtection.self) else
        {
            // TODO: this can cause execution cycle if observer will access keymaker.mainKey in the observation method
            NotificationCenter.default.post(.init(name: Keymaker.requestMainKey))
            return nil
        }
        
        // if we have NoneProtection active - get the key right ahead
        if let cypherText = NoneProtection.getCypherBits(from: self.keychain) {
            NotificationCenter.default.post(.init(name: Keymaker.obtainedMainKey))
            return try! NoneProtection(keychain: self.keychain).unlock(cypherBits: cypherText)
        }
        
        // otherwise there is no saved mainKey at all, so we should generate a new one with default protection
        let newKey = self.generateNewMainKeyWithDefaultProtection()
        NotificationCenter.default.post(.init(name: Keymaker.obtainedMainKey))
        return newKey
    }
    
    private let controlThread = DispatchQueue.global(qos: .userInteractive)
    
    public func wipeMainKey() {
        NoneProtection.removeCyphertext(from: self.keychain)
        BioProtection.removeCyphertext(from: self.keychain)
        PinProtection.removeCyphertext(from: self.keychain)
    }
    
    public func lockTheApp() {
        self._mainKey = nil
    }
    
    public func obtainMainKey(with protector: ProtectionStrategy,
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
            self._mainKey = mainKeyBytes
            isMainThread ? DispatchQueue.main.async { handler(self.mainKey) } : handler(self.mainKey)
        }
    }
    
    // completion says whether protector was activated or not
    public func activate(_ protector: ProtectionStrategy,
                           completion: @escaping (Bool)->Void)
    {
        let isMainThread = Thread.current.isMainThread
        self.controlThread.async {
            guard let mainKey = self.mainKey,
                let _ = try? protector.lock(value: mainKey) else
            {
                isMainThread ? DispatchQueue.main.async{ completion(false) } : completion(false)
                return
            }
            
            // we want to remove unprotected value from storage if the new Protector is significant
            if !(protector is NoneProtection) {
                self.deactivate(NoneProtection(keychain: self.keychain))
            }
            
            isMainThread ? DispatchQueue.main.async{ completion(true) } : completion(true)
        }
    }
    
    public func isProtectorActive<T: ProtectionStrategy>(_ protectionType: T.Type) -> Bool {
        return protectionType.getCypherBits(from: self.keychain) != nil
    }
    
    @discardableResult public func deactivate(_ protector: ProtectionStrategy) -> Bool {
        protector.removeCyphertextFromKeychain()
        
        // need to keep mainKey in keychain in case user switches off all the significant Protectors
        if !self.isProtectorActive(BioProtection.self), !self.isProtectorActive(PinProtection.self) {
            self.activate(NoneProtection(keychain: self.keychain), completion: { _ in })
        }
        
        return true
    }
    
    @discardableResult public func generateNewMainKeyWithDefaultProtection() -> Key {
        self.wipeMainKey() // get rid of all old protected mainKeys
        let newMainKey = NoneProtection.generateRandomValue(length: 32)
        self._mainKey = newMainKey
        try! NoneProtection(keychain: self.keychain).lock(value: newMainKey)
        return newMainKey
    }
    
    public func updateAutolockCountdownStart() {
        self.autolocker?.updateAutolockCountdownStart()
    }
}
