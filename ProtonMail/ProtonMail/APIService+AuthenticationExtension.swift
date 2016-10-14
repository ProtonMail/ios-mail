//
//  APIService+AuthenticationExtension.swift
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


/// Auth extension
extension APIService {
    
    
    func auth(username: String, password: String, completion: AuthComplete?) {
        
        AuthInfoRequest<AuthInfoResponse>(username: username).call() { task, res, hasError in
            if hasError {
                //return error
            } else if res?.code == 1000 {
                // caculate pwd
                guard let authVersion = res?.Version else {
                    // error
                    return
                }
                if (authVersion == 0) {
                    PMLog.D("")
                }
                
                guard let modulus = res?.Modulus else {
                    // error
                    return
                }
                
                guard let ephemeral = res?.ServerEphemeral else {
                    // error
                    return
                }
                
                guard let salt = res?.Salt else {
                    // error
                    return
                }
                
                guard let session = res?.SRPSession else {
                    return
                }
                
                let encodedModulus = sharedOpenPGP.readClearsignedMessage(modulus)
                let decodedModulus : NSData = encodedModulus.decodeBase64()
                let decodedSalt : NSData = salt.decodeBase64()
                let serverEphemeral : NSData = ephemeral.decodeBase64()
                
                var hashedPassword : NSData?
                
                switch authVersion {
                case 0:
                    hashedPassword = PasswordUtils.hashPasswordVersion0(password, username: username, modulus: decodedModulus)
                    break
                case 1:
                    hashedPassword = PasswordUtils.hashPasswordVersion1(password, username: username, modulus: decodedModulus)
                    break
                case 2:
                    hashedPassword = PasswordUtils.hashPasswordVersion2(password, username: username, modulus: decodedModulus)
                    break
                case 3:
                    hashedPassword = PasswordUtils.hashPasswordVersion3(password, salt: decodedSalt, modulus: decodedModulus)
                    break
                case 4:
                    hashedPassword = PasswordUtils.hashPasswordVersion4(password, salt: decodedSalt, modulus: decodedModulus)
                    break
                default: break
                }
                
                if hashedPassword == nil {
                    return
                }
                
                let srpClient = PMNSrpClient.generateProofs(2048, modulusRepr: decodedModulus, serverEphemeralRepr: serverEphemeral, hashedPasswordRepr: hashedPassword!)
                AuthRequest<AuthResponse>(username: username, ephemeral: srpClient.clientEphemeral, proof: srpClient.clientProof, session: session, code: "").call({ (task, res, hasError) in
                    if hasError {
                        if let error = res?.error {
                            if error.isInternetError() {
                                completion?(task: task, hasError: NSError.internetError())
                                return
                            } else {
                                completion?(task: task, hasError: error)
                                return
                            }
                        } else {
                            completion?(task: task, hasError: NSError.authInvalidGrant())
                        }
                    }
                    else if res?.code == 1000 {
                        guard let serverProof : NSData = res?.serverProof?.decodeBase64() else {
                            return
                        }
                        
                        if srpClient.expectedServerProof.isEqualToData(serverProof) {
                            let credential = AuthCredential(res: res)
                            credential.storeInKeychain()
                            completion?(task: task, hasError: nil)
                        } else {
                            // error server proof not match
                            completion?(task: task, hasError: NSError.authUnableToParseToken())
                        }
                    }
                    else {
                        completion?(task: task, hasError: NSError.authUnableToParseToken())
                    }
                })
            }
        }
    }
    
    func authRevoke(completion: AuthCredentialBlock?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            let path = "/auth/revoke"
            let parameters = ["access_token" : authCredential.token ?? ""]
            let completionWrapper: CompletionBlock = { _, _, error in
                completion?(nil, error)
                return
            }
            request(method: .POST, path: path, parameters: parameters, completion: completionWrapper)
        } else {
            completion?(nil, nil)
        }
    }
    func authRefresh(password:String, completion: AuthRefreshComplete?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            AuthRefreshRequest<AuthResponse>(resfresh: authCredential.refreshToken).call() { task, res , hasError in
                if hasError {
                    self.refreshTokenFailedCount += 1
                    if let err = res?.error {
                        err.uploadFabricAnswer(AuthErrorTitle)
                    }
                    
                    if self.refreshTokenFailedCount > 10 {
                        PMLog.D("self.refreshTokenFailedCount == 10")
                    }
                    
                    completion?(task: task, auth: nil, hasError: NSError.authInvalidGrant())
                }
                else if res?.code == 1000 {
                    do {
                        authCredential.update(res)
                        try authCredential.setupToken(password)
                        authCredential.storeInKeychain()
                        
                        PMLog.D("\(authCredential.description)")
                        
                        self.refreshTokenFailedCount = 0
                    } catch let ex as NSError {
                        PMLog.D(ex)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        completion?(task: task, auth: authCredential, hasError: nil)
                    }
                }
                else {
                    completion?(task: task, auth: nil, hasError: NSError.authUnableToParseToken())
                }
            }
        } else {
            completion?(task: nil, auth: nil, hasError: NSError.authCredentialInvalid())
        }
        
    }
}

extension AuthCredential {
    convenience init(authInfo: APIService.AuthInfo) {
        let expiration = NSDate(timeIntervalSinceNow: (authInfo.expiresId ?? 0))
        
        self.init(accessToken: authInfo.accessToken, refreshToken: authInfo.refreshToken, userID: authInfo.userID, expiration: expiration, key : "", plain: authInfo.accessToken, pwd: "")
    }
}

