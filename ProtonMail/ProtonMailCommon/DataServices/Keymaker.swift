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
    
    private(set) var mainKey: Key?
    
    static var shared = Keymaker()
    private let controlThread = DispatchQueue.global(qos: .utility)
    internal var currentProtector: ProtectionStrategy?
    
    private override init() {
        super.init()
        
        defer {
            self.obtainMainKey(with: self.currentProtector!) { // FIXME: get default protector somehow
                self.mainKey = $0
            }
        }
    }
    
    private func wipeMainKey() {
        sharedKeychain.keychain().removeItem(forKey: "mainKeyCypher")
    }
    
    private func lockTheApp() {
        self.mainKey = nil
    }
    
    private func obtainMainKey(with protector: ProtectionStrategy, into handler: (Key)->Void) {
        self.controlThread.sync {
            guard self.mainKey == nil else {
                handler(self.mainKey!)
                return
            }
            
            guard let cypherBits = sharedKeychain.keychain().data(forKey: "mainKeyCypher") else {
                let protector = NoneProtection()
                let mainKey = protector.generateRandomValue(length: 32)
                try! self.lock(mainKey: mainKey, with: [protector])
                handler(mainKey)
                return
            }

            if let mainKeyBytes = try? protector.unlock(cypherBits: cypherBits) {
                handler(mainKeyBytes)
            } else {
                // FIXME: unlock failed
            }
        }
    }
    
    private func lock(mainKey: Key, with protectors: Array<ProtectionStrategy>) throws {
        try protectors.forEach { try $0.lock(value: mainKey) }
    }
}
