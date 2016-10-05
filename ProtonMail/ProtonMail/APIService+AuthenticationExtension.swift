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
                
                guard let modulus = res?.Modulus else {
                    // error
                    return
                }
                
                guard let salt = res?.Salt else {
                    // error
                    return
                }
                
                let encodedModulus = sharedOpenPGP.readClearsignedMessage(modulus)
                let decodedModulus : NSData = encodedModulus.decodeBase64()
                let decodedSalt : NSData = salt.decodeBase64()
                
                switch authVersion {
                case 0: break
                case 1: break
                case 2: break
                case 3: break
                case 4:
                    let hashedPassword = PasswordUtils.hashPasswordVersion4(password, salt: decodedSalt, modulus: decodedModulus)
                    
                    let encoded = hashedPassword?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                    
                    let pwd = PasswordUtils.getMailboxPassword(password, salt: decodedSalt)
                    
                    PMLog.D("\(pwd)")
                    PMLog.D("\(hashedPassword)")
                    PMLog.D("\(encoded)")
                    break
                    
                default: break
                    
                }
                
                
//                        final byte[] hashedPassword;
//                        final OpenPgp openPgp = OpenPgp.createInstance();
//                        final byte[] modulus = Base64.decode(openPgp.readClearsignedMessage(infoResponse.getModulus()), Base64.DEFAULT);
//                        switch (authVersion) {
//                        case 4:
//                            hashedPassword = PasswordUtils.hashPasswordVersion4(password, Base64.decode(infoResponse.getSalt(), Base64.DEFAULT), modulus);
//                            break;
//                        case 3:
//                            hashedPassword = PasswordUtils.hashPasswordVersion3(password, Base64.decode(infoResponse.getSalt(), Base64.DEFAULT), modulus);
//                            break;
//                        case 2:
//                            if (!PasswordUtils.cleanUserName(username).equals(PasswordUtils.cleanUserName(infoResponse.getUserName()))) {
//                                return;
//                            }
//                            hashedPassword = PasswordUtils.hashPasswordVersion2(password, username, modulus);
//                            break;
//                        case 1:
//                            if (!username.toLowerCase().equals(infoResponse.getUserName().toLowerCase())) {
//                                return;
//                            }
//                            hashedPassword = PasswordUtils.hashPasswordVersion1(password, username, modulus);
//                            break;
//                        case 0:
//                            hashedPassword = PasswordUtils.hashPasswordVersion0(password, username, modulus);
//                            break;
//                        default:
//                            return;
//                        }
//                        final SRPClient.Proofs proofs = SRPClient.generateProofs(2048, modulus, Base64.decode(infoResponse.getServerEphemeral(), Base64.DEFAULT), hashedPassword);
//                        if (proofs != null) {
//                            final LoginResponse loginResponse = mApi.login(username, infoResponse.getSRPSession(), proofs.clientEphemeral, proofs.clientProof);
//                            if (ConstantTime.isEqual(proofs.expectedServerProof, Base64.decode(loginResponse.getServerProof(), Base64.DEFAULT))) {
//                                boolean foundErrorCode = checkForErrorCodes(loginResponse.getCode());
//                                if (!foundErrorCode && loginResponse.isValid()) {
//                                    status = LoginStatus.SUCCESS;
//                                    mUserManager.setUsername(username);
//                                    mTokenManager.update(loginResponse);
//                                } else {
//                                    status = LoginStatus.INVALID_CREDENTIAL;
//                                }
//                            } else {
//                                status = LoginStatus.INVALID_SERVER_PROOF;
//                            }
//                        }
//                    } else {
//                        status = LoginStatus.NO_NETWORK;
//                    }
//  
//                if (usedFallback && status.equals(LoginStatus.FAILED) && fallbackAuthVersion != 0) {
//                    final int newFallback;
//                    if (fallbackAuthVersion == 2 && !PasswordUtils.cleanUserName(username).equals(username.toLowerCase())) {
//                        newFallback = 1;
//                    } else {
//                        newFallback = 0;
//                    }
//                    
//                    startInfo(username, password, rememberMe, newFallback);
//                } else {
//                    AppUtil.postEventOnUi(new LoginEvent(status));
//                }
//                
//                private void handleLogin(String username, String password, boolean rememberMe, final LoginInfoResponse infoResponse, final int fallbackAuthVersion) {
//                    LoginStatus status = LoginStatus.FAILED;
//                    boolean usedFallback = false;
//                    try {
//                        if (mNetworkUtils.hasConnectivity(this)) {
//                            int authVersion = infoResponse.getAuthVersion();
//                            if (authVersion == 0) {
//                                usedFallback = true;
//                                authVersion = fallbackAuthVersion;
//                            }
//                            final byte[] hashedPassword;
//                            final OpenPgp openPgp = OpenPgp.createInstance();
//                            final byte[] modulus = Base64.decode(openPgp.readClearsignedMessage(infoResponse.getModulus()), Base64.DEFAULT);
//                            switch (authVersion) {
//                            case 4:
//                                hashedPassword = PasswordUtils.hashPasswordVersion4(password, Base64.decode(infoResponse.getSalt(), Base64.DEFAULT), modulus);
//                                break;
//                            case 3:
//                                hashedPassword = PasswordUtils.hashPasswordVersion3(password, Base64.decode(infoResponse.getSalt(), Base64.DEFAULT), modulus);
//                                break;
//                            case 2:
//                                if (!PasswordUtils.cleanUserName(username).equals(PasswordUtils.cleanUserName(infoResponse.getUserName()))) {
//                                    return;
//                                }
//                                hashedPassword = PasswordUtils.hashPasswordVersion2(password, username, modulus);
//                                break;
//                            case 1:
//                                if (!username.toLowerCase().equals(infoResponse.getUserName().toLowerCase())) {
//                                    return;
//                                }
//                                hashedPassword = PasswordUtils.hashPasswordVersion1(password, username, modulus);
//                                break;
//                            case 0:
//                                hashedPassword = PasswordUtils.hashPasswordVersion0(password, username, modulus);
//                                break;
//                            default:
//                                return;
//                            }
//                            final SRPClient.Proofs proofs = SRPClient.generateProofs(2048, modulus, Base64.decode(infoResponse.getServerEphemeral(), Base64.DEFAULT), hashedPassword);
//                            if (proofs != null) {
//                                final LoginResponse loginResponse = mApi.login(username, infoResponse.getSRPSession(), proofs.clientEphemeral, proofs.clientProof);
//                                if (ConstantTime.isEqual(proofs.expectedServerProof, Base64.decode(loginResponse.getServerProof(), Base64.DEFAULT))) {
//                                    boolean foundErrorCode = checkForErrorCodes(loginResponse.getCode());
//                                    if (!foundErrorCode && loginResponse.isValid()) {
//                                        status = LoginStatus.SUCCESS;
//                                        mUserManager.setUsername(username);
//                                        mTokenManager.update(loginResponse);
//                                    } else {
//                                        status = LoginStatus.INVALID_CREDENTIAL;
//                                    }
//                                } else {
//                                    status = LoginStatus.INVALID_SERVER_PROOF;
//                                }
//                            }
//                        } else {
//                            status = LoginStatus.NO_NETWORK;
//                        }
//                    } catch (Exception e) {
//                        Logger.doLogException(TAG, "error while login", e);
//                    }
//                    
//                    if (usedFallback && status.equals(LoginStatus.FAILED) && fallbackAuthVersion != 0) {
//                        final int newFallback;
//                        if (fallbackAuthVersion == 2 && !PasswordUtils.cleanUserName(username).equals(username.toLowerCase())) {
//                            newFallback = 1;
//                        } else {
//                            newFallback = 0;
//                        }
//                        
//                        startInfo(username, password, rememberMe, newFallback);
//                    } else {
//                        AppUtil.postEventOnUi(new LoginEvent(status));
//                    }
//                }
                
                
                
                
                AuthRequest<AuthResponse>(username: username, password: password).call() { task, res, hasError in
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
                        let credential = AuthCredential(res: res)
                        credential.storeInKeychain()
                        completion?(task: task, hasError: nil)
                    }
                    else {
                        completion?(task: task, hasError: NSError.authUnableToParseToken())
                    }
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

