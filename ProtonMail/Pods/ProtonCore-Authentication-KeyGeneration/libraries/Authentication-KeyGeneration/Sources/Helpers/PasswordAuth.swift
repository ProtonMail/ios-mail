//
//  PasswordAuth.swift
//  ProtonCore-Authentication-KeyGeneration - Created on 21.12.2020.
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
import ProtonCoreNetworking

public final class PasswordAuth: Package {

    public let authVersion: Int = 4

    /// encrypted id
    public let modulusID: String

    /// base64 encoded
    public let salt: String

    /// base64 encoded
    public let verifier: String

    public init(modulusID: String, salt: String, verifier: String) {
        self.modulusID = modulusID
        self.salt = salt
        self.verifier = verifier
    }

    public var parameters: [String: Any]? {
        let out: [String: Any] = [
            "Version": self.authVersion,
            "ModulusID": self.modulusID,
            "Salt": self.salt,
            "Verifier": self.verifier
        ]
        return out
    }
}
