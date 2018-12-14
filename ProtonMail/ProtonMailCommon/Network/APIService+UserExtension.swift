//
//  APIService+UserExtension.swift
//  ProtonMail
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

/// User extensions
extension APIService {
    
    public typealias UserInfoBlock = (UserInfo?, String?, NSError?) -> Void

    fileprivate struct UserPath {
        static let base = Constants.App.API_PATH + "/users"
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
                //setApiVesion(2, appVersion: 1)
                request(method: .get, path: path, parameters: nil, headers: ["x-pm-apiversion": 3], completion: { task, response, error in
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
        
        request(method: .put, path: path, parameters: parameters, headers: ["x-pm-apiversion": 3], completion: completion)
    }
    
    // MARK: private mothods
    fileprivate func isErrorResponse(_ response: Any!) -> NSError? {
        if let dict = response as? NSDictionary {
            if let code = dict["Code"] as? Int, code != 1000 && code != 1001 {
                let error = dict["Error"] as? String ?? ""
                let desc = dict["ErrorDescription"] as? String ?? ""
                return NSError.apiServiceError(code: code, localizedDescription: error, localizedFailureReason: desc, localizedRecoverySuggestion: "")
            } else {
                return nil
            }
        }
        
        return  NSError.unableToParseResponse(response)
    }
}
