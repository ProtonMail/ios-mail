//
//  APIService+UserExtension.swift
//  ProtonMail
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

/// User extensions
extension APIService {
    
    public typealias UserInfoBlock = (UserInfo?, String?, NSError?) -> Void

    fileprivate struct UserPath {
        static let base = "/users"
    }
    
    //deprecated
    func userPublicKeysForEmails(_ emails: [String], completion: CompletionBlock?) {
        let emailsString = emails.joined(separator: ",")
        
        userPublicKeysForEmails(emailsString, completion: completion)
    }
    
    //deprecated
    func userPublicKeysForEmails(_ emails: String, completion: CompletionBlock?) {
        PMLog.D("userPublicKeysForEmails -- \(emails)")
        if !emails.isEmpty {
            if let base64Emails = emails.base64Encoded() {
                let escapedValue : String? = base64Emails.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "/+=\n").inverted)
                let path = UserPath.base.stringByAppendingPathComponent("pubkeys").stringByAppendingPathComponent(escapedValue ?? base64Emails)
                request(method: .get, path: path, parameters: nil, headers: [HTTPHeader.apiVersion: 3], completion: { task, response, error in
                    PMLog.D("userPublicKeysForEmails -- res \(String(describing: response)) || error -- \(String(describing: error))")
                    if let paserError = self.isErrorResponse(response) {
                        completion?(task, response, paserError)
                    } else {
                        completion?(task, response, error)
                    }
                })
                return
            }
        }
        completion?(nil, nil, NSError.badParameter(emails))
    }
    
    //deprecated
    func userUpdateKeypair(_ pwd: String, publicKey: String, privateKey: String, completion: CompletionBlock?) {
        let path = UserPath.base + "/keys"
        let parameters = [
            "Password" : pwd,
            "PublicKey" : publicKey,
            "PrivateKey" : privateKey
        ]
        
        request(method: .put, path: path, parameters: parameters, headers: [HTTPHeader.apiVersion: 3], completion: completion)
    }
    
    // MARK: private mothods
    fileprivate func isErrorResponse(_ response: Any!) -> NSError? {
        if let dict = response as? NSDictionary {
            if let code = dict["Code"] as? Int, code != 1000 && code != 1001 {
                let error = dict["Error"] as? String ?? ""
                return NSError.apiServiceError(code: code,
                                               localizedDescription: error,
                                               localizedFailureReason: error,
                                               localizedRecoverySuggestion: "")
            } else {
                return nil
            }
        }
        
        return  NSError.unableToParseResponse(response)
    }
}
