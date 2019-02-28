//
//  APIService+AuthenticationExtension.swift
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
import PromiseKit

/// Auth extension
extension APIService {

    func auth(_ username: String, password: String, twoFACode: String?, authCredential: AuthCredential?, completion: AuthCompleteBlock!) {
        
        var forceRetry = false
        var forceRetryVersion = 2
        
        func tryAuth() {
            AuthInfoRequest(username: username, authCredential: authCredential).call() { task, res, hasError in
                if hasError {
                    guard let error = res?.error else {
                        return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                    }
                    if error.isInternetError() {
                        return completion(task, nil, .resCheck, NSError.internetError())
                    } else {
                        return completion(task, nil, .resCheck, error)
                    }
                } else if res?.code == 1000 {// caculate pwd
                    if let code = res?.TwoFactor {
                        if  code == 1 && twoFACode == nil {
                            return completion(task, nil, .ask2FA, nil)
                        }
                    }
                    guard let authVersion = res?.Version, let modulus = res?.Modulus, let ephemeral = res?.ServerEphemeral, let salt = res?.Salt, let session = res?.SRPSession else {
                        return completion(task, nil, .resCheck, NSError.authUnableToParseAuthInfo())
                    }
 
                    do {
                        if authVersion <= 2 && !forceRetry {
                            forceRetry = true
                            forceRetryVersion = 2
                        }

                        //init api calls
                        let hashVersion = forceRetry ? forceRetryVersion : authVersion
                        //move the error to the wrapper
                        guard let auth = try SrpAuth(hashVersion, username, password, salt, modulus, ephemeral) else {
                            return completion(task, nil, .resCheck, NSError.authUnableToGeneratePwd())
                        }
                        let srpClient = try auth.generateProofs(2048)
                        let api = AuthRequest(username: username,
                                              ephemeral: srpClient.clientEphemeral(),
                                              proof: srpClient.clientProof(),
                                              session: session,
                                              serverProof: srpClient.expectedServerProof(),
                                              code: twoFACode);
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
                                guard let res = res else {
                                    return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                                }
                                
                                guard let serverProof : Data = res.serverProof?.decodeBase64() else {
                                    return completion(task, nil, .resCheck, NSError.authServerSRPInValid())
                                }
                                
                                if api.serverProof == serverProof {
                                    let credential = AuthCredential(res: res)
                                    credential.storeInKeychain()
                                    let passwordMode = res.passwordMode
                                    var keySalt: String?
                                    var privateKey: String?
                                    
                                    func done() {
                                        credential.update(salt: keySalt, privateKey: privateKey)
                                        credential.storeInKeychain()
                                        if passwordMode == 1 {
                                            guard let keysalt : Data = keySalt?.decodeBase64() else {
                                                return completion(task, nil, .resCheck, NSError.authInValidKeySalt())
                                            }
                                            let mpwd = PasswordUtils.getMailboxPassword(password, salt: keysalt)
                                            return completion(task, mpwd, .resCheck, nil)
                                        } else {
                                            return completion(task, nil, .resCheck, nil)
                                        }
                                    }
                                    
                                    if !res.isEncryptedToken {
                                        credential.trySetToken()
                                        let saltapi = GetKeysSalts()
                                        saltapi.authCredential = credential
                                        let userApi = GetUserInfoRequest()
                                        userApi.authCredential = credential
                                        
                                        firstly {
                                            when(fulfilled: saltapi.run(), userApi.run())
                                        }.done { (saltRes, userRes)  in
                                            
                                           guard  let salt = saltRes.keySalt,
                                            let privatekey = userRes.userInfo?.getPrivateKey(by: saltRes.keyID) else {
                                                return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                                            }

                                            keySalt = salt
                                            privateKey = privatekey
                                            done()
                                        }.catch { err in
                                            let error = err as NSError
                                            if error.isInternetError() {
                                                return completion(task, nil, .resCheck, NSError.internetError())
                                            } else {
                                                return completion(task, nil, .resCheck, NSError.authInvalidGrant())
                                            }
                                        }
                                    } else {
                                        keySalt = res.keySalt
                                        privateKey = res.privateKey
                                        done()
                                    }
                                    
                                } else {
                                    return completion(task, nil, .resCheck, NSError.authServerSRPInValid())
                                }
                            } else {
                                return completion(task, nil, .resCheck, NSError.authUnableToParseToken())
                            }
                        }
                        api.call(completionWrapper)
                    } catch let err as NSError {
                        err.upload(toAnalytics: "tryAuth()")
                        return completion(task, nil, .resCheck, NSError.authUnableToParseAuthInfo())
                    }
                } else {
                    return completion(task, nil, .resCheck, NSError.authUnableToParseToken())
                }
            }
        }
        tryAuth()
    }
    
    func authRefresh(_ password:String, completion: AuthRefreshComplete?) {
        if let authCredential = AuthCredential.fetchFromKeychain() {
            AuthRefreshRequest<AuthResponse>(resfresh: authCredential.refreshToken, uid: authCredential.userID).call() { task, res , hasError in
                if hasError {
                    var needsRetry : Bool = false
                    if let err = res?.error {
                        err.upload(toAnalytics : AuthErrorTitle)
                        if err.code == NSURLErrorTimedOut ||
                            err.code == NSURLErrorNotConnectedToInternet ||
                            err.code == NSURLErrorCannotConnectToHost ||
                            err.code == APIErrorCode.API_offline ||
                            err.code == APIErrorCode.HTTP503 {
                            needsRetry = true
                        } else {
                            self.refreshTokenFailedCount += 1
                        }
                    }
                    
                    if self.refreshTokenFailedCount > 5 || !needsRetry {
                        PMLog.D("self.refreshTokenFailedCount == 5")
                        completion?(task, nil, NSError.authInvalidGrant())
                    } else {
                        completion?(task, nil, NSError.internetError())
                    }
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


