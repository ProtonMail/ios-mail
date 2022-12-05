//
//  Generator.swift
//  ProtonCore-Crypto - Created on 07/19/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

public enum Generator {
    
    public static func generateECCKey(email: String, passphase: Passphrase) throws -> ArmoredKey{
        var error: NSError?
        // in our system the PGP `User ID Packet-Tag 13` we use email address as username and email address
        let armoredUserKey = HelperGenerateKey(email, email, passphase.data,
                                               PublicKeyAlgorithms.x25519.raw, 0, &error)
        if let err = error {
            throw err
        }
        return ArmoredKey.init(value: armoredUserKey)
    }
}
