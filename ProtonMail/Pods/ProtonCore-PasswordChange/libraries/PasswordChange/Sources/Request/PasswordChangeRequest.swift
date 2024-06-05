//
//  PasswordChangeRequest.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreDataModel
import ProtonCoreNetworking

/// Settings API
///
/// Documentation: https://protonmail.gitlab-pages.protontech.ch/Slim-API/account/#tag/Settings
struct SettingsAPI {
    static let Path: String = "/settings"
}

/// Update login password request. Only called in 2-password mode (or onboarding to 2-password mode).
///
/// Documentation: https://protonmail.gitlab-pages.protontech.ch/Slim-API/account/#tag/Settings/operation/put_core-%7B_version%7D-settings-password
final class PasswordChangeRequest: Request {
    let clientEphemeral: String
    let clientProof: String
    let srpSession: String
    let twoFACode: String?
    let modulusID: String
    let salt: String
    let verifier: String

    init(clientEphemeral: String, clientProof: String, srpSession: String, twoFACode: String?, modulusID: String, salt: String, verifier: String) {
        self.clientEphemeral = clientEphemeral
        self.clientProof = clientProof
        self.srpSession = srpSession
        self.twoFACode = twoFACode
        self.modulusID = modulusID
        self.salt = salt
        self.verifier = verifier
    }

    var parameters: [String: Any]? {
        let auth: [String: Any] = [
            "Version": 4,
            "ModulusID": modulusID,
            "Salt": salt,
            "Verifier": verifier
        ]
        var result: [String: Any] = [
            "ClientEphemeral": clientEphemeral,
            "ClientProof": clientProof,
            "SRPSession": srpSession,
            "Auth": auth
        ]
        if let code = twoFACode {
            result["TwoFactorCode"] = code
        }
        return result
    }

    var method: HTTPMethod { .put }
    var path: String {
        SettingsAPI.Path + "/password"
    }
}
