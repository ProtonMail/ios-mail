//
//  Session.swift
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

/// value is case sensitive. use lower case
/// Symmetric-Key Algorithms
public enum Algorithm: String {
    case ThreeDES  = "3des"
    case TripleDES = "tripledes" // Both "3des" and "tripledes" refer to 3DES.
    case CAST5     = "cast5"
    case AES128    = "aes128"
    case AES192    = "aes192"
    case AES256    = "aes256"
    
    public var value: String {
        return self.rawValue
    }
}

// session key that used to encrypt the data packet
public class SessionKey {
    public init(sessionKey: Data, algo: Algorithm) {
        self.sessionKey = sessionKey
        self.algo = algo
    }
    
    public let sessionKey: Data
    public let algo: Algorithm
}
