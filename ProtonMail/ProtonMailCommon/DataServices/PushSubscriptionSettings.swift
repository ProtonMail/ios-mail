//
//  PushSubscriptionSettings.swift
//  ProtonMail - Created on 08/11/2018.
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
#if !APP_EXTENSION
import OpenPGP
#endif

#if !APP_EXTENSION
import OpenPGP
#endif

struct PushSubscriptionSettings: Hashable, Codable {
    let token, UID: String
    var encryptionKit: EncryptionKit!
    
    static func == (lhs: PushSubscriptionSettings, rhs: PushSubscriptionSettings) -> Bool {
        return lhs.token == rhs.token && lhs.UID == rhs.UID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.token)
        hasher.combine(self.UID)
    }
    
    init(token: String, UID: String) {
        self.token = token
        self.UID = UID
    }
    
    #if !APP_EXTENSION
    mutating func generateEncryptionKit() throws {
        let keypair = try Crypto.generateRandomKeyPair()
        self.encryptionKit = EncryptionKit(passphrase: keypair.passphrase, privateKey: keypair.privateKey, publicKey: keypair.publicKey)
    }
    #endif
}
