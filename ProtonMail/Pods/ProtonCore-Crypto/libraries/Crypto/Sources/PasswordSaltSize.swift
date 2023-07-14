//
//  PasswordSaltSize.swift
//  ProtonCore-Crypto - Created on 08/14/22.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

// 80 bit for a login password.  128 for key password.
public enum PasswordSaltSize {
    case login  // login/auth
    case accountKey  // account key/mailboxpassword
    case addressKey  // address key
    
    public var int32Bits: Int32 {
        switch self {
        case .login:
            return 80
        case .accountKey:
            return 128
        case .addressKey:
            return 256
        }
    }
    
    public var int32Bytes: Int32 {
        int32Bits / 8
    }
    
    public var IntBits: Int {
        Int(self.int32Bits)
    }
    
    public var IntBytes: Int {
        Int(self.int32Bytes)
    }
}
