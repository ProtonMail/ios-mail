//
//  Password.swift
//  ProtonCore-Crypto - Created on 07/15/22.
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
import ProtonCore_Utilities

public enum PasswordType {
    public enum Key {}
    public enum Random {}
    public enum Token {}
}

public struct Password<Type> {
    public init(value: String) {
        self.value = value.trimmingCharacters(in: CharacterSet.newlines)
    }
    public let value: String
    public var isEmpty: Bool {
        value.isEmpty
    }
}
public typealias Passphrase = Password<PasswordType.Key>
public typealias TokenPassword = Password<PasswordType.Token>

// extra helpers
extension Password {
    public var data: Data? {
        return self.value.utf8
    }
}

extension Password where Type == PasswordType.Key {
    
    public func encrypt(publicKey: ArmoredKey) throws -> ArmoredMessage {
        return try publicKey.encrypt(clearText: self.value)
    }
    
    public func signDetached(signer: SigningKey) throws -> ArmoredSignature {
        return try Sign.signDetached(signingKey: signer, plainText: self.value)
    }
}
