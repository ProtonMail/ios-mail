//
//  SrpClientExtension.swift
//  ProtonMail - Created on 10/18/16.
//
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
import Crypto

func SrpAuth(_ hashVersion: Int, _ userName: String, _ password: String,
             _ salt: String, _ signedModulus: String, _ serverEphemeral: String) throws -> SrpAuth? {
    var error : NSError?
    let outAuth = SrpNewAuth(hashVersion, userName, password, salt, signedModulus, serverEphemeral, &error)

    if let err = error {
        throw err
    }
    return outAuth
}

func SrpAuthForVerifier(_ password: String, _ signedModulus: String, _ rawSalt: Data) throws -> SrpAuth? {
    var error : NSError?
    let outAuth = SrpNewAuthForVerifier(password, signedModulus, rawSalt, &error)
    if let err = error {
        throw err
    }
    return outAuth
}
