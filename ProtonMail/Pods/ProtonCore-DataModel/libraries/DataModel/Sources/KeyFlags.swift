//
//  KeyFlags.swift
//  ProtonCore-DataModel - Created on 08/14/22
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

public struct KeyFlags: OptionSet, Decodable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// 1: Can use key to verify signatures | Key is not compromised
    public static let verifySignatures = KeyFlags(rawValue: 1 << 0)
    /// 2: Can use key to encrypt new data | Key is not obsolete
    public static let encryptNewData = KeyFlags(rawValue: 1 << 1)
    /// 4: Cannot be used to encrypt an email | External address key
    public static let cannotEncryptEmail = KeyFlags(rawValue: 1 << 2)
    /// 8: Emails from this address will not come signed | External address key
    public static let dontExpectSignedEmails = KeyFlags(rawValue: 1 << 3)
    
    /// 3: default value when signup 1 + 2
    public static let signupKeyFlags: KeyFlags = [.verifySignatures, .encryptNewData]
    /// 12: value for checking if the key is external address key 4 + 8
    public static let signifyingExternalAddress: KeyFlags = [.cannotEncryptEmail, .dontExpectSignedEmails]
    /// 15: default value when signup external 1 + 2 + 4 + 8
    public static let signupExternalKeyFlags: KeyFlags = [.verifySignatures, .encryptNewData, .cannotEncryptEmail, .dontExpectSignedEmails]
    /// all -- contains all
    public static let all: KeyFlags = [.verifySignatures, .encryptNewData, .cannotEncryptEmail, .dontExpectSignedEmails]
}
