//
//  OrganizationsAPI.swift
//  ProtonMail - Created on 11/15/16.
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
import PMCommon

//Organization API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_organizations.md
struct OrganizationsAPI {
    static let Path : String = "/organizations"
}

final class OrgKeyResponse : Response {
    var privKey : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}

//MARK : get keys salt -- OrgKeyResponse
/// Get organization keys [GET]
final class GetOrgKeys : Request {
    var path: String {
        return OrganizationsAPI.Path + "/keys"
    }
    var parameters: [String : Any]? {
        return nil
    }
}
