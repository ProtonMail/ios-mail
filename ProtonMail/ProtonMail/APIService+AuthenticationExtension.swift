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
                
            } else if res?.code == 1000 {
                // caculate pwd
                guard let authVersion = res?.Version else {
                    // error
                    return
                }
                if (authVersion == 0) {
                    PMLog.D("")
                }

//                let modulus = "\n-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\nS/hBgmVXHlpzUxgzOlt4veE3v3BnpaVyRFUUDMmRgcF2yZU5rQcQYHDBGrnQAlGdcsGmZVcZC51JgJtEB6v5bBpxnnsjg8XibZm0GYXODhm7qki5wM5AEKoTKbZKaKuRD297pPTsVdqUdXFNdkDxk3Q3nv3N6ZEJccCS1IabllN+/adVTjUfCMA9pyJavOOj90fhcCQ2npInsxegvlGvREr1JpobdrtbXAOzLH+9ELxpW91ZFWbN0HHaE8+JV8TsZnhY+W0pqL+x18iVBwOCKjqiNVlXsJsd4PV0fyX3Fb/uRTnUuEYe/98xo+qqG/CrhIW7QgiuwemEN7PdHHARnQ==\n-----BEGIN PGP SIGNATURE-----\nVersion: OpenPGP.js v1.2.0\nComment: http://openpgpjs.org\n\n\n=twTO\n-----END PGP SIGNATURE-----\n"
                guard let modulus = res?.Modulus else {
                    // error
                    return
                }
                
 //               let ephemeral = "WgJaHogUuZTCa4vPkLMVbx6PXmkFl+Y2Z9YLWBaQAOXPxDzlajMbqUT0YQWQm6VBkubMBZ/DdH7YQoJ3sr7AFWRIT0AdZ3qskqOAf3Qrrxa4Tp3HZ2n2y2JGG2g1sthR2P+/TdKslkhPRIORgWFNC5IWg8bDNdIKv0VJO9F7Bx2zgRSMtM8zPIQlBjYwZguYjuz4x1TkuiZwUAkYujOdJ9Ykuo3gbykj0Wy33v/cMrpdZV3UUJr8D4R3Rjx+QYMD8JbdK95SY0850u2AGxCVR0aEnj9bkAgypHuTC9NC8dHgu54D6O1P66b7Un56vZEO9P1HaVt0V9m+Us0Tevt9Iw=="
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
                
                //let session = "7c4b3eb9308a58b0a0d27b2d53a7902e"
                
               //// "Salt": "rLf2G74r8Xe5HA==",
               // "SRPSession": "7c4b3eb9308a58b0a0d27b2d53a7902e",
                let encodedModulus = sharedOpenPGP.readClearsignedMessage(modulus)
                let decodedModulus : NSData = encodedModulus.decodeBase64()
                let decodedSalt : NSData = salt.decodeBase64()
                
                switch authVersion {
                case 0: break
                case 1: break
                case 2: break
                case 3: break
                case 4:
                    if let hashedPassword = PasswordUtils.hashPasswordVersion4(password, salt: decodedSalt, modulus: decodedModulus) {
                        let ServerEphemeral : NSData = ephemeral.decodeBase64()
                        let srpClient = PMNSrpClient.generateProofs(2048, modulusRepr: decodedModulus, serverEphemeralRepr: ServerEphemeral, hashedPasswordRepr: hashedPassword)
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
                                
               
//                                    final LoginResponse loginResponse = mApi.login(username, infoResponse.getSRPSession(), proofs.clientEphemeral, proofs.clientProof);
//                                    if (ConstantTime.isEqual(proofs.expectedServerProof, Base64.decode(loginResponse.getServerProof(), Base64.DEFAULT))) {
//                                        boolean foundErrorCode = checkForErrorCodes(loginResponse.getCode());
//                                        if (!foundErrorCode && loginResponse.isValid()) {
//                                            status = LoginStatus.SUCCESS;
//                                            mUserManager.setUsername(username);
//                                            mTokenManager.update(loginResponse);
//                                        } else {
//                                            status = LoginStatus.INVALID_CREDENTIAL;
//                                        }
//                                    } else {
//                                        status = LoginStatus.INVALID_SERVER_PROOF;
//                                    }
//                            } else {
//                                status = LoginStatus.NO_NETWORK;
//                            }
//                            
//                            if (usedFallback && status.equals(LoginStatus.FAILED) && fallbackAuthVersion != 0) {
//                                final int newFallback;
//                                if (fallbackAuthVersion == 2 && !PasswordUtils.cleanUserName(username).equals(username.toLowerCase())) {
//                                    newFallback = 1;
//                                } else {
//                                    newFallback = 0;
//                                }
//                                
//                                startInfo(username, password, rememberMe, newFallback);
//                            } else {
//                                AppUtil.postEventOnUi(new LoginEvent(status));
//                            }
                            

                                
                                
                                
                                
                                let credential = AuthCredential(res: res)
                                credential.storeInKeychain()
                                completion?(task: task, hasError: nil)
                            }
                            else {
                                completion?(task: task, hasError: NSError.authUnableToParseToken())
                            }
                        })
                    }
                    break
                default: break
                    
                }
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

