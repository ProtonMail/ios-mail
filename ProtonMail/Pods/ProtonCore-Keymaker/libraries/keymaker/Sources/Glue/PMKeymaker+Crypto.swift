//
//  PMKeymaker+Crypto.swift
//  PMKeymaker - Created on 12/03/2020.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import Foundation
import Crypto

public struct CryptoSubtle: SubtleProtocol {
    public static func Random(_ len: Int) -> Data? {
        var error: NSError?
        return CryptoRandomToken(len, &error)
    }
    
    public static func DeriveKey(_ one: String, _ two: Data, _ three: Int, _ four: inout NSError?) -> Data? {
        return SubtleDeriveKey(one, two, three, &four)
    }
    public static func EncryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data? {
        return SubtleEncryptWithoutIntegrity(one, two, three, &four)
    }
    public static func DecryptWithoutIntegrity(_ one: Data, _ two: Data, _ three: Data, _ four: inout NSError?) -> Data? {
        return SubtleDecryptWithoutIntegrity(one, two, three, &four)
    }
}

public typealias LockedErrors = Errors
public typealias Locked<T> = GenericLocked<T, CryptoSubtle>
public typealias BioProtection = GenericBioProtection<CryptoSubtle>
public typealias PinProtection = GenericPinProtection<CryptoSubtle>
public typealias Keymaker = GenericKeymaker<CryptoSubtle>
public typealias StringCryptoTransformer = GenericStringCryptoTransformer<CryptoSubtle>
