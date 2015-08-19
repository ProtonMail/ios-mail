//
//  APIService+UserExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

/// User extensions
extension APIService {
    
    typealias UserInfoBlock = (UserInfo?, NSError?) -> Void
    typealias UserNameCheckBlock = (Bool, NSError?) -> Void
    

    private struct UserPath {
        static let base = "/users"
    }
    
    func userInfo(completion: UserInfoBlock) {
        fetchAuthCredential() { authCredential, error in
            if let authCredential = authCredential {
                let path = UserPath.base;//.stringByAppendingPathComponent(authCredential.userID)
                
                let completionWrapper: CompletionBlock = { task, response, error in
                    if error != nil {
                        completion(nil, error)
                    } else if let response = response {
                        if let errorres = self.isErrorResponse(response) {
                            completion(nil, errorres)
                        }else {
                            println("\(response)")
                            let userInfo = UserInfo(
                                response: response["User"] as! Dictionary<String, AnyObject>,
                                displayNameResponseKey: "DisplayName",
                                maxSpaceResponseKey: "MaxSpace",
                                notificationEmailResponseKey: "NotificationEmail",
                                privateKeyResponseKey: "EncPrivateKey",
                                publicKeyResponseKey: "PublicKey",
                                signatureResponseKey: "Signature",
                                usedSpaceResponseKey: "UsedSpace",
                                userStatusResponseKey: "UserStatus",
                                userAddressResponseKey: "Addresses")
                            
                            completion(userInfo, nil)
                        }
                    } else {
                        completion(nil, NSError.unableToParseResponse(response))
                    }
                }
                
                self.request(method: .GET, path: path, parameters: nil, completion: completionWrapper)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func userPublicKeyForUsername(username: String, completion: CompletionBlock?) {
        let path = UserPath.base.stringByAppendingPathComponent("pubkey").stringByAppendingPathComponent(username)
        
        request(method: .GET, path: path, parameters: nil, completion: completion)
    }
    
    func userPublicKeysForEmails(emails: Array<String>, completion: CompletionBlock?) {
        let emailsString = ",".join(emails)
        
        userPublicKeysForEmails(emailsString, completion: completion)
    }
    
    func userPublicKeysForEmails(emails: String, completion: CompletionBlock?) {
        if !emails.isEmpty {
            if let base64Emails = emails.base64Encoded() {
                let path = UserPath.base.stringByAppendingPathComponent("pubkeys").stringByAppendingPathComponent(base64Emails)
                
                setApiVesion(2, appVersion: 1)
                request(method: .GET, path: path, parameters: nil, completion: { task, response, error in
                    var error = error
                    var response = response
                    
                    if (self.isErrorResponse(response) != nil) {
//                        let errorCode = (response!["Code"] as! Int) ?? 0
//                        let description = (response!["Error"] as! NSDictionary).description ?? NSLocalizedString("Unknown error")
//                        error = NSError.protonMailError(code: errorCode, localizedDescription: description)
                    }
                    
                    completion?(task: task, response: response, error: error)
                })
                return
            }
        }
        completion?(task: nil, response: nil, error: NSError.badParameter(emails))
    }
    
    func userUpdateKeypair(pwd: String, publicKey: String, privateKey: String, completion: CompletionBlock?) {
        let path = UserPath.base.stringByAppendingPathComponent("keys")
        let parameters = [
            "Password" : pwd,
            "PublicKey" : publicKey,
            "PrivateKey" : privateKey
        ]
        setApiVesion(2, appVersion: 1)
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
    
    func userCheckExist(user_name:String, completion: UserNameCheckBlock) {
        let path = UserPath.base.stringByAppendingPathComponent("check").stringByAppendingPathComponent(user_name)
        request(method: .GET, path: path, parameters: nil, authenticated: false, completion:{ task, response, error in
            
            if error == nil {
                if (self.isErrorResponse(response) != nil) {
                    completion(false, NSError.userNameTaken())
                }
                else {
                    completion(true, nil)
                }
            }
            else
            {
                completion(false, error)
            }
        })
    }
    
    // MARK: private mothods
    private func isErrorResponse(response: AnyObject!) -> NSError? {
        if let dict = response as? NSDictionary {
            let code = dict["Code"] as! Int
            if (code != 1000)
            {
                let error = dict["Error"] as! String;
                let desc = dict["ErrorDescription"] as! String;
                return NSError.apiServiceError(code: code, localizedDescription: error, localizedFailureReason: desc, localizedRecoverySuggestion: "")
            }
            else
            {
                return nil
            }
        }
        
        return  NSError.unableToParseResponse(response)
    }
}

// MARK: - UserInfo extension

extension UserInfo {
    
    /// Initializes the UserInfo with the response data
    convenience init(
        response: Dictionary<String, AnyObject>,
        displayNameResponseKey: String,
        maxSpaceResponseKey: String,
        notificationEmailResponseKey: String,
        privateKeyResponseKey: String,
        publicKeyResponseKey: String,
        signatureResponseKey: String,
        usedSpaceResponseKey: String,
        userStatusResponseKey:String,
        userAddressResponseKey:String) {
            var addresses: [Address] = Array<Address>()
            let address_response = response[userAddressResponseKey] as! Array<Dictionary<String, AnyObject>>
            for res in address_response
            {
                addresses.append(Address(
                    addressid: res["ID"] as? String,
                    email:res["Email"] as? String,
                    send: res["Send"] as? Int,
                    receive: res["Receive"] as? Int,
                    mailbox: res["Mailbox"] as? Int,
                    display_name: res["DisplayName"] as? String,
                    signature: res["Signature"] as? String))
            }
            let usedS = response[usedSpaceResponseKey] as? NSNumber
            let maxS = response[maxSpaceResponseKey] as? NSNumber
            self.init(
                displayName: response[displayNameResponseKey] as? String,
                maxSpace: maxS?.longLongValue,
                notificationEmail: response[notificationEmailResponseKey] as? String,
                privateKey: response[privateKeyResponseKey] as? String,
                publicKey: response[publicKeyResponseKey] as? String,
                signature: response[signatureResponseKey] as? String,
                usedSpace: usedS?.longLongValue,
                userStatus: response[userStatusResponseKey] as? Int,
                userAddresses: addresses)
    }
}
