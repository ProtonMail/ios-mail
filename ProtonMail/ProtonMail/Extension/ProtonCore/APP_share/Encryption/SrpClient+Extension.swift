//
//  SrpClientExtension.swift
//  Proton Mail - Created on 10/18/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import GoLibs
import OpenPGP
import ProtonCore_Crypto

func SrpAuth(_ hashVersion: Int, _ userName: String, _ password: String,
             _ salt: String, _ signedModulus: String, _ serverEphemeral: String) throws -> SrpAuth? {
    var error: NSError?
    let passwordSlic = password.data(using: .utf8)
    let outAuth = SrpNewAuth(hashVersion, userName, passwordSlic, salt, signedModulus, serverEphemeral, &error)

    if let err = error {
        throw err
    }
    return outAuth
}

func SrpAuthForVerifier(_ password: Passphrase, _ signedModulus: String, _ rawSalt: Data) throws -> SrpAuth? {
    var error: NSError?
    let passwordSlic = Data(password.value.utf8)
    let outAuth = SrpNewAuthForVerifier(passwordSlic, signedModulus, rawSalt, &error)
    if let err = error {
        throw err
    }
    return outAuth
}
