//
//  FIDO2Context.swift
//  ProtonCore-Authentication - Created on 29/04/24.
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
import ProtonCoreAPIClient
import ProtonCoreServices
import ProtonCoreNetworking

/// Holds the bits necessary for signing a FIDO2 challenge
public struct FIDO2Context {
    public let credential: Credential
    public let passwordMode: PasswordMode
}

/// FIDO2 signature details provided by the key
public struct Fido2Signature {
    /// signed challenge
    public let signature: Data
    /// id of credential used to sign
    public let credentialID: Data
    /// data about the authenticator
    public let authenticatorData: Data
    /// data about the client
    public let clientData: Data
    /// original `AuthenticationOptions` used as challenge
    public let authenticationOptions: AuthenticationOptions

    /// Memberwise initializer
    public init(signature: Data, credentialID: Data, authenticatorData: Data, clientData: Data, authenticationOptions: AuthenticationOptions) {
        self.signature = signature
        self.credentialID = credentialID
        self.authenticatorData = authenticatorData
        self.clientData = clientData
        self.authenticationOptions = authenticationOptions
    }
}
