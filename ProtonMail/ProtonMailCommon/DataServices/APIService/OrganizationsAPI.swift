//
//  OrganizationsAPI.swift
//  ProtonMail - Created on 11/15/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

//MARK : get keys salt
final class GetOrgKeys : ApiRequest<OrgKeyResponse> {
    
    override func method() -> APIService.HTTPMethod {
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
