//
//  PinProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CryptoSwift

struct PinProtection: ProtectionStrategy {
    private let pin: String
    init(pin: String) {
        self.pin = pin
    }
    
    func lock(value: Keymaker.Key) throws {
        // 1. generate new salt
        // 2. derive key from pin and salt
        // 3. encrypt mainKey with ethemeralKey
        // 4. save salt in keychain
        // 5. save encryptedMainKey in keychain
        
        let salt = self.generateRandomValue(length: 8)
        let ethemeralKey = try PKCS5.PBKDF2(password: Array(pin.utf8), salt: salt, iterations: 4096, variant: .sha256).calculate()
        let locked = try Locked<Keymaker.Key>(clearValue: value, with: ethemeralKey)
        
        self.saveCyphertextInKeychain(locked.encryptedValue)
        // TODO: save salt in keychain
    }
}
