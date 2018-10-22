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
    enum AutolockTimeout: RawRepresentable {
        case never
        case always
        case minutes(Int)
        
        init(rawValue: Int) {
            switch rawValue {
            case -1: self = .never
            case 0: self = .always
            case let number: self = .minutes(number)
            }
        }
        
        var rawValue: Int {
            switch self {
            case .never: return -1
            case .always: return 0
            case .minutes(let number): return number
            }
        }
    }
    
    static let requestMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".requestMainKey")
    static let obtainedMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".obtainedMainKey")
    typealias Key = Array<UInt8>
    
    // stored in-memory value
    private var _mainKey: Key? {
        didSet {
            if _mainKey != nil {
                self.autolockCountdownStart = nil
            }
        }
    }
    
    // accessor for stored value; if stored value is nill - calls provokeMainKeyObtention() method
    internal var mainKey: Key? {
        if self.shouldAutolockNow() {
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
            NotificationCenter.default.post(.init(name: Keymaker.requestMainKey))
            return nil
        }
        
        // if we have NoneProtection active - get the key right ahead
        if let cypherText = NoneProtection.getCypherBits() {
            NotificationCenter.default.post(.init(name: Keymaker.obtainedMainKey))
            return try! NoneProtection().unlock(cypherBits: cypherText)
        }
        
        // otherwise there is no saved mainKey at all, so we should generate a new one with default protection
        let newKey = self.generateNewMainKeyWithDefaultProtection()
        NotificationCenter.default.post(.init(name: Keymaker.obtainedMainKey))
        return newKey
    }
    
    static var shared = Keymaker()
    private let controlThread = DispatchQueue.global(qos: .utility)
    
    internal func wipeMainKey() {
        // TODO: remove additional keychain items of all protectors
        NoneProtection.removeCyphertextFromKeychain()
        BioProtection.removeCyphertextFromKeychain()
        PinProtection.removeCyphertextFromKeychain()
    }
    
    internal func lockTheApp() {
        self._mainKey = nil
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
            self._mainKey = mainKeyBytes
            isMainThread ? DispatchQueue.main.async { handler(self.mainKey) } : handler(self.mainKey)
        }
    }
    
    // completion says whether protector was activated or not
    internal func activate(_ protector: ProtectionStrategy,
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
                self.deactivate(NoneProtection())
            }
            
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
    
    @discardableResult func generateNewMainKeyWithDefaultProtection() -> Key {
        self.wipeMainKey() // get rid of all old protected mainKeys
        
        let newMainKey = NoneProtection.generateRandomValue(length: 32)
        try! NoneProtection().lock(value: newMainKey)
        self._mainKey = newMainKey
        return newMainKey
    }
    

    // there is no need to persist this value anywhere except memory since we can not unlock the app automatically after relaunch (except NoneProtection case)
    // by the same reason we can benefit from system uptime value instead of current Date which can be played with in Settings.app
    private var autolockCountdownStart: TimeInterval?
    
    internal func updateAutolockCountdownStart() {
        self.autolockCountdownStart = ProcessInfo().systemUptime
    }
    
    private func shouldAutolockNow() -> Bool {
        // no countdown started - no need to lock
        guard let lastBackgroundedAt = self.autolockCountdownStart else {
            return false
        }
        
        switch userCachedStatus.lockTime {
        case .always: return true
        case .never: return false
        case .minutes(let numberOfMinutes):
            return TimeInterval(numberOfMinutes * 60) < ProcessInfo().systemUptime - lastBackgroundedAt
        }
    }
}
