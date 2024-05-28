//
//  AuthInfoResponse.swift
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
import ProtonCoreNetworking

/**
 A class representing the data required to compute the SRP
 */
public final class AuthInfoResponse: Response, APIDecodableResponse {
    public var modulus: String
    public var serverEphemeral: String
    public var version: Int
    public var salt: String
    public var srpSession: String
    public var _2FA: TwoFA?

    public init(modulus: String, serverEphemeral: String, version: Int, salt: String, srpSession: String, _2FA: TwoFA? = nil) {
        self.modulus = modulus
        self.serverEphemeral = serverEphemeral
        self.version = version
        self.salt = salt
        self.srpSession = srpSession
        self._2FA = _2FA
    }

    public enum CodingKeys: String, CodingKey {
        case modulus
        case serverEphemeral
        case version
        case salt
        case srpSession = "SRPSession"
        case _2FA = "2FA"
    }

    required init() {
        self.modulus = ""
        self.serverEphemeral = ""
        self.version = 0
        self.salt = ""
        self.srpSession = ""
        self._2FA = nil
    }

    public convenience init(_ response: [String: Any]!) throws {
        guard
            let modulus = response["Modulus"] as? String,
            let serverEphemeral = response["ServerEphemeral"] as? String,
            let version = response["Version"] as? Int,
            let salt = response["Salt"] as? String,
            let srpSession = response["SRPSession"] as? String else {
            throw AuthErrors.switchToSSOError
        }
        self.init(
            modulus: modulus,
            serverEphemeral: serverEphemeral,
            version: version,
            salt: salt,
            srpSession: srpSession,
            _2FA: response["2FA"] as? TwoFA
        )
    }

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        guard
            let modulus = response["Modulus"] as? String,
            let serverEphemeral = response["ServerEphemeral"] as? String,
            let version = response["Version"] as? Int,
            let salt = response["Salt"] as? String,
            let srpSession = response["SRPSession"] as? String else {
            return false
        }
        self.modulus = modulus
        self.serverEphemeral = serverEphemeral
        self.version = version
        self.salt = salt
        self.srpSession = srpSession
        self._2FA = response["2FA"] as? TwoFA
        return true
    }

    public struct TwoFA: Codable {

        public var enabled: EnabledMechanism
        public var FIDO2: Fido2?

        public init(enabled: EnabledMechanism, fido2: Fido2? = nil) {
            self.enabled = enabled
            self.FIDO2 = fido2
        }
    }
}
