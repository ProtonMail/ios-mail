//
//  OrgKeyResponse.swift
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

import Foundation
import ProtonCoreNetworking

/// Organization API
///
/// Documentation: https://protonmail.gitlab-pages.protontech.ch/Slim-API/account/#tag/Organization
struct OrganizationsAPI {
    static let Path: String = "/organizations"
}

/// Get PGP keys of the current organization request
///
/// Documentation: https://protonmail.gitlab-pages.protontech.ch/Slim-API/account/#tag/Organization/operation/get_core-%7B_version%7D-organizations-keys
final class OrganizationKeysRequest: Request {
    var path: String {
        return OrganizationsAPI.Path + "/keys"
    }
    var parameters: [String: Any]? {
        return nil
    }
}

/// `OrgKeyResponse` is the response returned by ``OrganizationKeysRequest``. Although the request
/// returns more values, we only care about the `PrivateKey`
final class OrgKeyResponse: Response, Codable {
    /// Organization private key encrypted with mailbox password hash
    var privKey: String?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
