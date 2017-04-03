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

    func auth(_ username: String, password: String, twoFACode: String?, completion: AuthCompleteBlock!) {
        
        var forceRetry = false
        var forceRetryVersion = 2
        
        func tryAuth() {
            AuthInfoRequest<AuthInfoResponse>(username: username).call() { task, res, hasError in
                if hasError {
                    guard let error = res?.error else {
                        return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                    }
                    if error.isInternetError() {
                        return completion(task, nil, .resCheck, NSError.internetError())
                    } else {
                        return completion(task, nil, .resCheck, error)
                    }
                }
                else if res?.code == 1000 {// caculate pwd
                    if let code = res?.TwoFactor {
                        if  code == 1 && twoFACode == nil {
                            return completion(task, nil, .ask2FA, nil)
                        }
                    }
                    guard let authVersion = res?.Version, let modulus = res?.Modulus, let ephemeral = res?.ServerEphemeral, let salt = res?.Salt, let session = res?.SRPSession else {
                        return completion(task, nil, .resCheck, NSError.authUnableToParseAuthInfo())
                    }
                    
                    do {
                        guard let encodedModulus = try modulus.getSignature() else {
                            return completion(task, nil, .resCheck, NSError.authUnableToParseAuthInfo())
                        }
                        let decodedModulus : Data = encodedModulus.decodeBase64()
                        let decodedSalt : Data = salt.decodeBase64()
                        let serverEphemeral : Data = ephemeral.decodeBase64()
                        if authVersion <= 2 && !forceRetry {
                            forceRetry = true
                            forceRetryVersion = 2
                        }
                        //init api calls
                        let hashVersion = forceRetry ? forceRetryVersion : authVersion
                        guard let hashedPassword = PasswordUtils.getHashedPwd(hashVersion, password: password, username: username, decodedSalt: decodedSalt, decodedModulus: decodedModulus) else {
                            return completion(task, nil, .resCheck, NSError.authUnableToGeneratePwd())
                        }
                        
                        guard let srpClient = try generateSrpProofs(2048, modulus: decodedModulus, serverEphemeral: serverEphemeral, hashedPassword: hashedPassword), srpClient.isValid() == true else {
                            return completion(task, nil, .resCheck, NSError.authUnableToGenerateSRP())
                        }
                        
                        let api = AuthRequest<AuthResponse>(username: username, ephemeral: srpClient.clientEphemeral, proof: srpClient.clientProof, session: session, serverProof: srpClient.expectedServerProof, code: twoFACode);
                        let completionWrapper: (_ task: URLSessionDataTask?, _ res: AuthResponse?, _ hasError : Bool) -> Void = { (task, res, hasError) in
                            if hasError {
                                if let error = res?.error {
                                    if error.isInternetError() {
                                        return completion(task, nil, .resCheck, NSError.internetError())
                                    } else {
                                        if forceRetry && forceRetryVersion != 0 {
                                            forceRetryVersion -= 1
                                            tryAuth()
                                        } else {
                                            return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                                        }
                                    }
                                } else {
                                    return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                                }
                            } else if res?.code == 1000 {
                                guard let serverProof : Data = res?.serverProof?.decodeBase64() else {
                                    return completion(task, nil, .resCheck, NSError.authServerSRPInValid())
                                }
                                
                                if api.serverProof == serverProof {
                                    let credential = AuthCredential(res: res)
                                    credential.storeInKeychain()
                                    if res?.passwordMode == 1 {
                                        guard let keysalt : Data = res?.keySalt?.decodeBase64() else {
                                            return completion(task, nil, .resCheck, NSError.authInValidKeySalt())
                                        }
                                        let mpwd = PasswordUtils.getMailboxPassword(password, salt: keysalt)
                                        return completion(task, mpwd, .resCheck, nil)
                                    } else {
                                        return completion(task, nil, .resCheck, nil)
                                    }
                                } else {
                                    return completion(task, nil, .resCheck, NSError.authServerSRPInValid())
                                }
                            } else {
                                return completion(task, nil, .resCheck, NSError.authUnableToParseToken())
                            }
                        }
                        api.call(completionWrapper)
                    } catch {
                        return completion(task, nil, .resCheck, NSError.authUnableToParseAuthInfo())
                    }
                }
                else {
                    return completion(task, nil, .resCheck, NSError.authUnableToParseToken())
                }
            }
        }
        tryAuth()
    }
    
    func authRevoke(_ completion: AuthCredentialBlock?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            let path = "/auth/revoke"
            let parameters = ["access_token" : authCredential.token ?? ""]
            let completionWrapper: CompletionBlock = { _, _, error in
                completion?(nil, error)
                return
            }
            request(method: .post, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completionWrapper)
        } else {
            completion?(nil, nil)
        }
    }
    func authRefresh(_ password:String, completion: AuthRefreshComplete?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            AuthRefreshRequest<AuthResponse>(resfresh: authCredential.refreshToken, uid: authCredential.userID).call() { task, res , hasError in
                if hasError {
                    self.refreshTokenFailedCount += 1
                    if let err = res?.error {
                        err.uploadFabricAnswer(AuthErrorTitle)
                    }
                    
                    if self.refreshTokenFailedCount > 10 {
                        PMLog.D("self.refreshTokenFailedCount == 10")
                    }
                    
                    completion?(task, nil, NSError.authInvalidGrant())
                }
                else if res?.code == 1000 {
                    do {
                        authCredential.update(res)
                        try authCredential.setupToken(password)
                        authCredential.storeInKeychain()
                        
                        PMLog.D("\(authCredential.description)")
                        
                        self.refreshTokenFailedCount = 0
                    } catch let ex as NSError {
                        PMLog.D(any: ex)
                    }
                    DispatchQueue.main.async {
                        completion?(task, authCredential, nil)
                    }
                }
                else {
                    completion?(task, nil, NSError.authUnableToParseToken())
                }
            }
        } else {
            completion?(nil, nil, NSError.authCredentialInvalid())
        }
        
    }
}

extension AuthCredential {
    convenience init(authInfo: APIService.AuthInfo) {
        let expiration = Date(timeIntervalSinceNow: (authInfo.expiresId ?? 0))
        
        self.init(accessToken: authInfo.accessToken, refreshToken: authInfo.refreshToken, userID: authInfo.userID, expiration: expiration, key : "", plain: authInfo.accessToken, pwd: "", salt: "")
    }
}

