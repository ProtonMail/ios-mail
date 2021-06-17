//
//  PasswordAuth.swift
//  PMAuthentication - Created on 21.12.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

/// message packages
final class PasswordAuth {

    let AuthVersion: Int = 4
    
    /// encrypted id
    let ModulusID: String
    
    /// base64 encoded
    let salt: String
    
    /// base64 encoded
    let verifer: String

    init(modulus_id: String, salt: String, verifer: String) {
        self.ModulusID = modulus_id
        self.salt = salt
        self.verifer = verifer
    }

    // Mark : override class functions
    func toDictionary() -> [String: Any]? {
        let out: [String: Any] = [
            "Version": self.AuthVersion,
            "ModulusID": self.ModulusID,
            "Salt": self.salt,
            "Verifier": self.verifer
        ]
        return out
    }
}
