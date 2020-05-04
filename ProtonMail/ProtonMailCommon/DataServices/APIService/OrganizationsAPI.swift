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

//MARK : get keys salt
final class GetOrgKeys : ApiRequest<OrgKeyResponse> {
    
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return OrganizationsAPI.Path + "/keys" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return OrganizationsAPI.v_get_org_keys
    }
}

final class OrgKeyResponse : ApiResponse {
    var privKey : String?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.privKey = response["PrivateKey"] as? String
        return true
    }
}
