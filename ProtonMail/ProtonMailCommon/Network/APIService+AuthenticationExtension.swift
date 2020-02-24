//
//  APIService+AuthenticationExtension.swift
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
import PromiseKit
import PMAuthentication

/// Auth extension
extension APIService {
    func auth2fa(res: AuthResponse, password: String, twoFACode: String?, checkSalt: Bool = true, completion: @escaping AuthCompleteBlock) {
        let credential = AuthCredential(res: res)
        
        func exec() {
            let passwordMode = res.passwordMode
            var keySalt: String?
            var privateKey: String?
            
            func done(userInfo: UserInfo?) {
                credential.update(salt: keySalt, privateKey: privateKey)
                if passwordMode == 1 {
                    guard let keysalt : Data = keySalt?.decodeBase64() else {
                        return completion(nil, nil, .resCheck, nil, nil, userInfo, NSError.authInValidKeySalt())
                    }
                    let mpwd = PasswordUtils.getMailboxPassword(password, salt: keysalt)
                    return completion(nil, mpwd, .resCheck, nil, credential, userInfo, nil)
                } else {
                    return completion(nil, nil, .resCheck, nil, credential, userInfo, nil)
                }
            }
            
            if !res.isEncryptedToken {
                let saltapi = GetKeysSalts(api: self)
                ///
                if !checkSalt {
                    done(userInfo: nil)
                } else {
                    saltapi.authCredential = credential
                    let userApi = GetUserInfoRequest(api: self)
                    userApi.authCredential = credential
                    firstly {
                        when(fulfilled: saltapi.run(), userApi.run())
                    }.done { (saltRes, userRes)  in
                        guard  let salt = saltRes.keySalt,
                            let privatekey = userRes.userInfo?.getPrivateKey(by: saltRes.keyID) else {
                                return completion(nil, nil, .resCheck, nil, nil, userRes.userInfo, NSError.authInvalidGrant())
                        }
                        keySalt = salt
                        privateKey = privatekey
                        done(userInfo: userRes.userInfo)
                    }.catch { err in
                        let error = err as NSError
                        if error.isInternetError() {
                            return completion(nil, nil, .resCheck, nil, nil, nil, NSError.internetError())
                        } else {
                            return completion(nil, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                        }
                    }
                }
                ///
            } else {
                keySalt = res.keySalt
                privateKey = res.privateKey
                done(userInfo: nil)
            }
        }
        
        if let code = twoFACode {
            let tfaapi = TwoFARequest(api: self, code: code)
            tfaapi.authCredential = credential
            firstly {
                tfaapi.run()
            }.done { (res) in
                if let error = res.error {
                    return completion(nil, nil, .resCheck, nil, nil, nil, error)
                } else {
                    exec()
                }
            }.catch { err in
                let error = err as NSError
                if error.isInternetError() {
                    return completion(nil, nil, .resCheck, nil, nil, nil, NSError.internetError())
                } else {
                    return completion(nil, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                }
            }
        } else {
            exec()
        }
    }
    
    
    
    func auth(_ username: String, password: String,
              twoFACode: String?, authCredential: AuthCredential?,
              checkSalt: Bool = true, completion: AuthCompleteBlock!) {
        
        var forceRetry = false
        var forceRetryVersion = 2
        
            AuthInfoRequest(username: username, authCredential: authCredential).call(api: self) { task, res, hasError in
                if hasError {
                    guard let error = res?.error else {
                        return completion(task, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                    }
                    if error.isInternetError() {
                        return completion(task, nil, .resCheck, nil, nil, nil, NSError.internetError())
                    } else {
                        return completion(task, nil, .resCheck, nil, nil, nil, error)
                    }
                } else if res?.code == 1000 {// caculate pwd
                    guard let authVersion = res?.Version, let modulus = res?.Modulus,
                        let ephemeral = res?.ServerEphemeral, let salt = res?.Salt, let session = res?.SRPSession else {
                            return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToParseAuthInfo())
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
                            return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToGeneratePwd())
                        }
                        
                        let srpClient = try auth.generateProofs(2048)
                        guard let clientEphemeral = srpClient.clientEphemeral,
                            let clientProof = srpClient.clientProof, let expectedServerProof = srpClient.expectedServerProof else {
                                return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToGenerateSRP())
                        }
                        
                        let api = AuthRequest(username: username,
                                              ephemeral: clientEphemeral,
                                              proof: clientProof,
                                              session: session,
                                              serverProof: expectedServerProof,
                                              code: twoFACode);
                        let completionWrapper: (_ task: URLSessionDataTask?, _ res: AuthResponse?, _ hasError : Bool) -> Void = { (task, res, hasError) in
                            if hasError {
                                if let error = res?.error {
                                    if error.isInternetError() {
                                        return completion(task, nil, .resCheck, nil, nil, nil, NSError.internetError())
                                    } else {
                                        if forceRetry && forceRetryVersion != 0 {
                                            forceRetryVersion -= 1
                                            self.auth(username, password: password, twoFACode: twoFACode, authCredential: authCredential, completion: completion)
                                        } else {
                                            return completion(task, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                                        }
                                    }
                                } else {
                                    return completion(task, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                                }
                            } else if res?.code == 1000 {
                                guard let res = res else {
                                    return completion(task, nil, .resCheck, nil, nil, nil, NSError.authInvalidGrant())
                                }
                                
                                guard let serverProof : Data = res.serverProof?.decodeBase64() else {
                                    return completion(task, nil, .resCheck,  nil,nil, nil, NSError.authServerSRPInValid())
                                }
                                
                                if api.serverProof == serverProof {
                                    let credential = AuthCredential(res: res)
//                                    credential.storeInKeychain()
                                    //if 2fa enabled
                                    if res.twoFactor != 0 {
                                        return completion(task, nil, .ask2FA, res, credential, nil, nil)
                                    }
                                    //if 2fa disabled
                                    self.auth2fa(res: res, password: password, twoFACode: twoFACode, checkSalt: checkSalt, completion: completion)
                                } else {
                                    return completion(task, nil, .resCheck, nil, nil, nil, NSError.authServerSRPInValid())
                                }
                            } else {
                                return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToParseToken())
                            }
                        }
                        api.call(api: self, completionWrapper)
                    } catch let err as NSError {
                        err.upload(toAnalytics: "tryAuth()")
                        return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToParseAuthInfo())
                    }
                } else {
                    return completion(task, nil, .resCheck, nil, nil, nil, NSError.authUnableToParseToken())
                }
            }
        
    }
    
    
    
    func authRefresh(_ authCredential: AuthCredential, completion: AuthRefreshComplete?) {
        let oldCredential = PMAuthentication.Credential(authCredential)
        self.authApi.refreshCredential(oldCredential) { result in
            switch result {
            case .success(let status):
                guard case Authenticator.Status.updatedCredential(let newCredential) = status else {
                    assert(false, "Was trying to refresh credential but got something else instead")
                    PMLog.D("Was trying to refresh credential but got something else instead")
                    completion?(nil, nil, NSError.authInvalidGrant())
                }
                self.refreshTokenFailedCount = 0
                completion?(nil, newCredential, nil)
                
            case .failure(let error):
                var err: NSError = error as NSError
                if case Authenticator.Errors.serverError(let serverResponse) = error {
                    err = serverResponse
                }
                
                var needsRetry : Bool = false
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
                
                if self.refreshTokenFailedCount > 5 || !needsRetry {
                    PMLog.D("self.refreshTokenFailedCount == 5")
                    completion?(nil, nil, NSError.authInvalidGrant())
                } else {
                    completion?(nil, nil, NSError.internetError())
                }
            }
        }
    }
}

extension PMAuthentication.Credential {
    init(_ authCredential: AuthCredential) {
        self.init(UID: authCredential.sessionID,
                  accessToken: authCredential.accessToken,
                  refreshToken: authCredential.refreshToken,
                  expiration: authCredential.expiration,
                  scope: [])
    }
}
