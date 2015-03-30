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
    
    
    struct UserErrorCode {
        static let userOK = 1000
        static let userNameExsit = 12011
        static let currentWrong = 12021
        static let newNotMatch = 12022
        static let pwdUpdateFailed = 12023
        static let pwdEmpty = 12024
    }
    
    private struct UserPath {
        static let base = "/users"
    }
    
    func userInfo(completion: UserInfoBlock) {
        fetchAuthCredential() { authCredential, error in
            if let authCredential = authCredential {
                let path = UserPath.base.stringByAppendingPathComponent(authCredential.userID)
                
                let completionWrapper: CompletionBlock = { task, response, error in
                    if error != nil {
                        completion(nil, error)
                    } else if let response = response {
                        let userInfo = UserInfo(
                            response: response,
                            displayNameResponseKey: "DisplayName",
                            maxSpaceResponseKey: "MaxSpace",
                            notificationEmailResponseKey: "NotificationEmail",
                            privateKeyResponseKey: "EncPrivateKey",
                            publicKeyResponseKey: "PublicKey",
                            signatureResponseKey: "Signature",
                            usedSpaceResponseKey: "UsedSpace",
                            userStatusResponseKey: "UserStatus",
                            userAddressResponseKey: "addresses")
                        
                        completion(userInfo, nil)
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
                
                request(method: .GET, path: path, parameters: nil, completion: { task, response, error in
                    var error = error
                    var response = response
                    
                    if self.isErrorResponse(response) {
                        let errorCode = (response!["code"] as Int) ?? 0
                        let description = (response!["error"] as NSDictionary).description ?? NSLocalizedString("Unknown error")
                        error = NSError.protonMailError(code: errorCode, localizedDescription: description)
                    }
                    
                    completion?(task: task, response: response, error: error)
                })
                return
            }
        }
        
        completion?(task: nil, response: nil, error: NSError.badParameter(emails))
    }
    
    func userUpdateKeypair(publicKey: String, privateKey: String, completion: CompletionBlock?) {
        let path = UserPath.base.stringByAppendingPathComponent("key")
        let parameters = [
            "public" : publicKey,
            "private" : privateKey
        ]
        
        request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
    
    func userCheckExist(user_name:String, completion: UserNameCheckBlock) {
        let path = UserPath.base.stringByAppendingPathComponent("check").stringByAppendingPathComponent(user_name)
        request(method: .GET, path: path, parameters: nil, authenticated: false, completion:{ task, response, error in
            
            if error == nil {
                if self.isErrorResponse(response) {
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
    private func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            return dict["error"] != nil
        }
        
        return false
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
            let address_response = response[userAddressResponseKey] as Array<Dictionary<String, AnyObject>>
            for res in address_response
            {
                addresses.append(Address(
                    addressid: res["AddressID"] as? Int,
                    email:res["Email"] as? String,
                    send: res["Send"] as? Int,
                    receive: res["Receive"] as? Int,
                    mailbox: res["Mailbox"] as? Int,
                    display_name: res["DisplayName"] as? String,
                    signature: res["Signature"] as? String))
            }
            self.init(
                displayName: response[displayNameResponseKey] as? String,
                maxSpace: response[maxSpaceResponseKey] as? Int,
                notificationEmail: response[notificationEmailResponseKey] as? String,
                privateKey: response[privateKeyResponseKey] as? String,
                publicKey: response[publicKeyResponseKey] as? String,
                signature: response[signatureResponseKey] as? String,
                usedSpace: response[usedSpaceResponseKey] as? Int,
                userStatus: response[userStatusResponseKey] as? Int,
                userAddresses: addresses)
    }
}

extension NSError {
    
    class func userNameTaken() -> NSError {
        return apiServiceError(
            code: APIService.UserErrorCode.userNameExsit,
            localizedDescription: NSLocalizedString("Invalid UserName"),
            localizedFailureReason: NSLocalizedString("The UserName have been taken."))
    }
    
    class func currentPwdWrong() -> NSError {
        return apiServiceError(
            code: APIService.UserErrorCode.currentWrong,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The Password is wrong."))
    }
    
    class func newNotMatch() -> NSError {
        return apiServiceError(
            code: APIService.UserErrorCode.newNotMatch,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The new password not match"))
    }
    
    class func pwdCantEmpty() -> NSError {
        return apiServiceError(
            code: APIService.UserErrorCode.pwdEmpty,
            localizedDescription: NSLocalizedString("Change Password"),
            localizedFailureReason: NSLocalizedString("The new password can't empty"))
    }
}
