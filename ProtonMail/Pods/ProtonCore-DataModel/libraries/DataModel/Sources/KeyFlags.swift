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
    public static let verifySignatures          = KeyFlags(rawValue: 1 << 0)
    /// 2: Can use key to encrypt new data | Key is not obsolete
    public static let encryptNewData            = KeyFlags(rawValue: 1 << 1)
    /// 4: Belongs to an external address
    public static let belongsToExternalAddress  = KeyFlags(rawValue: 1 << 2)
    /// 3: default value when signup  1 + 2
    public static let signupKeyFlags: KeyFlags  = [.verifySignatures, .encryptNewData]
    /// all
    public static let all: KeyFlags             = [.verifySignatures, .encryptNewData, .belongsToExternalAddress]
}
