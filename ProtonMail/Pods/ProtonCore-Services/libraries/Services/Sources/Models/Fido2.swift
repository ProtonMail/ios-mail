//
//  Fido2.swift
//  ProtonCore-Services - Created on 25.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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

public struct Fido2: Codable {
    public let authenticationOptions: AuthenticationOptions?
    public let registeredKeys: [RegisteredKey]
}

public struct AuthenticationOptions: Codable {
    public let publicKey: PublicKey

    public var challenge: Data {
        publicKey.challenge
    }

    public var relyingPartyIdentifier: String {
        publicKey.rpId
    }

    public var allowedCredentialIds: [Data] {
        publicKey.allowCredentials.map(\.id)
    }
 }

public struct PublicKey: Codable {
    public let timeout: Int
    public let challenge: Data
    public let userVerification: String
    public let rpId: String
    public let allowCredentials: [AllowedCredential]
}

public struct AllowedCredential: Codable {
    public let id: Data
    public let type: String
}

public struct EnabledMechanism: OptionSet, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let off: EnabledMechanism = []
    public static let both: EnabledMechanism = [.totp, .webAuthn]
    public static let totp = EnabledMechanism(rawValue: 1 << 0)
    public static let webAuthn = EnabledMechanism(rawValue: 1 << 1)
}

public struct RegisteredKey: Codable, Identifiable {
    public let attestationFormat: String
    public let credentialID: Data
    public let name: String

    public var id: Data {
        credentialID
    }
}

extension RegisteredKey {
    /// Sample init for Preview
    public init(number: Int) {
        self.attestationFormat = "packed"
        self.credentialID = UUID().uuidString.data(using: .utf8)!
        self.name = "Key \(number)"
    }
}
