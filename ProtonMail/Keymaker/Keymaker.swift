//
//  Keymaker.swift
//  ProtonMail - Created on 13/10/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import EllipticCurveKeyPair

public class Keymaker: NSObject {
    public static let removedMainKeyFromMemory: NSNotification.Name = .init(String(describing: Keymaker.self) + ".removedMainKeyFromMemory")
    public static let errorObtainingMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".errorObtainingMainKey")
    public static let obtainedMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".obtainedMainKey")
    public static let requestMainKey: NSNotification.Name = .init(String(describing: Keymaker.self) + ".requestMainKey")
    public typealias Key = Array<UInt8>
    
    private var autolocker: Autolocker?
    private let keychain: Keychain
    public init(autolocker: Autolocker?, keychain: Keychain) {
        self.autolocker = autolocker
        self.keychain = keychain
        
        super.init()
        defer {
            if #available(iOS 13.0, *) {
                NotificationCenter.default.addObserver(self, selector: #selector(mainKeyExists),
                                                       name: UIWindowScene.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(mainKeyExists),
                                                       name: UIWindowScene.didActivateNotification, object: nil)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(mainKeyExists),
                                                       name: UIApplication.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(mainKeyExists),
                                                       name: UIApplication.didBecomeActiveNotification, object: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // stored in-memory value
    private var _mainKey: Key? {
        didSet {
            if _mainKey != nil {
                self.resetAutolock()
                self.setupCryptoTransformers(key: _mainKey)
            } else {
                NotificationCenter.default.post(name: Keymaker.removedMainKeyFromMemory, object: self)
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
    
    public func resetAutolock() {
        self.autolocker?.releaseCountdown()
    }
    
    // Try to get main key from storage if it exists, otherwise create one.
    // if there is any significant Protection active - post message that obtainMainKey(_:_:) is needed
    private func provokeMainKeyObtention() -> Key? {
        // if we have any significant Protector - wait for obtainMainKey(_:_:) method to be called
        guard !self.isProtectorActive(BioProtection.self),
            !self.isProtectorActive(PinProtection.self) else
        {
            // TODO: this can cause execution cycle if observer will access keymaker.mainKey in the observation method
            //TODO::fixme ^ is right. better to use the delegate in the app entry
            NotificationCenter.default.post(.init(name: Keymaker.requestMainKey))
            return nil
        }
        
        // if we have NoneProtection active - get the key right ahead
        if let cypherText = NoneProtection.getCypherBits(from: self.keychain) {
            return try! NoneProtection(keychain: self.keychain).unlock(cypherBits: cypherText)
        }
        
        // otherwise there is no saved mainKey at all, so we should generate a new one with default protection
        let newKey = self.generateNewMainKeyWithDefaultProtection()
        return newKey
    }
    
    private let controlThread = DispatchQueue.global(qos: .userInteractive)
    
    public func wipeMainKey() {
        NoneProtection.removeCyphertext(from: self.keychain)
        BioProtection.removeCyphertext(from: self.keychain)
        PinProtection.removeCyphertext(from: self.keychain)
        
        self._mainKey = nil
        self.setupCryptoTransformers(key: nil)
    }
    
    @discardableResult @objc
    public func mainKeyExists() -> Bool { // cuz another process can wipe main key from memory while the app is in background
        if !self.isProtectorActive(BioProtection.self),
            !self.isProtectorActive(PinProtection.self),
            !self.isProtectorActive(NoneProtection.self)
        {
            self._mainKey = nil
            NotificationCenter.default.post(.init(name: Keymaker.requestMainKey))
            return false
        }
        if let _ = self._mainKey {
            self.resetAutolock()
        }
        return true
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
            guard self._mainKey == nil else {
                isMainThread ? DispatchQueue.main.async { handler(self._mainKey) } : handler(self._mainKey)
                return
            }
            
            guard let cypherBits = protector.getCypherBits() else {
                isMainThread ? DispatchQueue.main.async { handler(nil) } : handler(nil)
                return
            }

            do {
                let mainKeyBytes = try protector.unlock(cypherBits: cypherBits)
                self._mainKey = mainKeyBytes
                NotificationCenter.default.post(name: Keymaker.obtainedMainKey, object: self)
            } catch let error {
                NotificationCenter.default.post(name: Keymaker.errorObtainingMainKey, object: self, userInfo: ["error": error])
                
                // this CFError trows randomly on iOS 13 (up to 13.3 beta 2) on TouchID capable devices
                // it happens less if auth prompt is invoked with 1 sec delay after app gone foreground but still happens
                // description: "Could not decrypt. Failed to get externalizedContext from LAContext"
                if #available(iOS 13.0, *),
                    case EllipticCurveKeyPair.Error.underlying(message: _, error: let underlyingError) = error,
                    underlyingError.code == -2
                {
                    isMainThread
                        ? DispatchQueue.main.async { self.obtainMainKey(with: protector, handler: handler) }
                        : self.obtainMainKey(with: protector, handler: handler)
                } else {
                    self._mainKey = nil
                }
            }
            
            isMainThread ? DispatchQueue.main.async { handler(self._mainKey) } : handler(self._mainKey)
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
    
    private func generateNewMainKeyWithDefaultProtection() -> Key {
        self.wipeMainKey() // get rid of all old protected mainKeys
        let newMainKey = NoneProtection.generateRandomValue(length: 32)
        try! NoneProtection(keychain: self.keychain).lock(value: newMainKey)
        return newMainKey
    }
    
    private func setupCryptoTransformers(key: Key?) {
        guard let key = key else {
            ValueTransformer.setValueTransformer(nil, forName: .init(rawValue: String(describing: StringCryptoTransformer.self)))
            return
        }
        ValueTransformer.setValueTransformer(StringCryptoTransformer(key: key),
                                             forName: .init(rawValue: String(describing: StringCryptoTransformer.self)))
    }
    
    public func updateAutolockCountdownStart() {
        self.autolocker?.updateAutolockCountdownStart()
        let _ = self.mainKey
    }
}
