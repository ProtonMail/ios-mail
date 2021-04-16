//
//  UserDataService.swift
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
import AwaitKit
import PromiseKit
import PMKeymaker
import Crypto
import PMAuthentication
import PMCommon

class KeyManager : Service {
    
    /// key version for migration
    enum KeyVersion {
        case v1_1
        case v1_2
    }

    /// ccurrent signup key version . 1.1. going to use v1.2 later. keep using the v1.1 key when signup
    let curSignupKeyVersion:KeyVersion = .v1_1
    
    
    /// srp builder errors
    enum SRPError : Int, Error, CustomErrorVar {
        case invalidModulsID
        case invalidModuls
        case cantGenerateVerifier
        
        var code : Int {
            return self.rawValue
        }
        
        var desc : String {
            return LocalString._update_notification_email
        }
        
        var reason : String {
            switch self {
            case .invalidModulsID:
                return LocalString._cant_get_a_moduls_id
            case .invalidModuls:
                return LocalString._cant_get_a_moduls
            case .cantGenerateVerifier:
                return LocalString._cant_create_a_srp_verifier
            }
        }
    }
    
    /// api service
    let apiService : APIService
    
    init(api: APIService) {
        self.apiService = api
    }
    
    /// generatPasswordAuth SRPClient. block api call in side
    /// - Parameter password: plaint text login password
    /// - Throws: SRPError
    /// - Returns: password auth : PasswordAuth
    func generatPasswordAuth(password: String, authCredential: AuthCredential? = nil) throws -> PasswordAuth {
        let authModuls: AuthModulusResponse = try await(self.apiService.run(route: AuthModulusRequest(authCredential: authCredential)))
        guard let moduls_id = authModuls.ModulusID else {
            throw SRPError.invalidModulsID
        }
        guard let new_moduls = authModuls.Modulus else {
            throw SRPError.invalidModuls
        }
        //generat new verifier
        let new_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
        guard let srp = try SrpAuthForVerifier(password, new_moduls, new_salt) else {
            throw SRPError.cantGenerateVerifier
        }
        let verifier = try srp.generateVerifier(2048)
        return PasswordAuth(modulus_id: moduls_id,
                            salt: new_salt.encodeBase64(),
                            verifer: verifier.encodeBase64())
    }
    
    /// upload the user key. key 1.2 function.  don't use it in signup flow.
    /// - Parameters:
    ///   - userName: user name
    ///   - loginPassword: plain text login password
    ///   - keySalt: password key salt
    ///   - privateKey: private key
    ///   - authCredential: customized auth credential
    /// - Throws: exception
    private func uploadUserKey(userName: String, loginPassword: String, keySalt: String, privateKey: String, authCredential: AuthCredential?) throws {
        // get auto info fors srp client
        let info: AuthInfoResponse = try await(self.apiService.run(route: AuthInfoRequest(username: userName, authCredential: authCredential)))
        guard let modulus = info.Modulus, let ephemeral = info.ServerEphemeral, let salt = info.Salt, let session = info.SRPSession else {
            throw UpdatePasswordError.invalideAuthInfo.error
        }
        
        //
        let authPassword = try self.generatPasswordAuth(password: loginPassword, authCredential: authCredential)
        
        //init api calls
        let hashVersion = 4
        guard let srp = try SrpAuth(hashVersion, userName, loginPassword, salt, modulus, ephemeral) else {
            throw UpdatePasswordError.cantHashPassword.error
        }
        let srpClient = try srp.generateProofs(2048)
        guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
            throw UpdatePasswordError.cantGenerateSRPClient.error
        }
        
        let uploadKeyApi = UpdatePrivateKeyRequest(clientEphemeral: clientEphemeral.encodeBase64(),
                                                   clientProof:clientProof.encodeBase64(),
                                                   SRPSession: session,
                                                   keySalt: keySalt,
                                                   userlevelKeys: [],
                                                   addressKeys: [],
                                                   tfaCode: nil,
                                                   orgKey: nil,
                                                   userKeys: nil,
                                                   auth: authPassword,
                                                   authCredential: authCredential)
        
        let update_res = try await(self.apiService.run(route: uploadKeyApi))
        guard update_res.code == 1000 else {
            throw UpdatePasswordError.default.error
        }
        //sucessed
    }
    
    
    /// init address and setup key auto switch key version
    /// - Parameters:
    ///   - password: plain text password
    ///   - keySalt: password key salt
    ///   - keyPassword: password with key salt
    ///   - privateKey: private key user/address
    ///   - domain: the domain user signup
    ///   - authCredential: customized auth credential
    /// - Throws: exceptions
    func initAddressKey(password: String, keySalt: String, keyPassword: String, privateKey: String, domain: String, authCredential: AuthCredential? = nil) throws {
        switch curSignupKeyVersion {
        case .v1_1:
            try self.initAddrKey1_1(password: password, keySalt: keySalt, keyPassword: keyPassword, privateKey: privateKey,
                                    domain: domain, authCredential: authCredential)
        case .v1_2:
            try self.initAddrKey1_2(password: password, keySalt: keySalt, keyPassword: keyPassword, privateKey: privateKey,
                                    domain: domain, authCredential: authCredential)
        }
    }
    
    /// 1.1 key
    func initAddrKey1_1(password: String, keySalt: String, keyPassword: String, privateKey: String,
                        domain: String, authCredential: AuthCredential? = nil) throws {
        
        //need setup address
        let setupAddrApi: AddressesResponse = try await(self.apiService.run( route: SetupAddressRequest(domain_name: domain, auth: authCredential)))
        
        let passwordAuth = try self.generatPasswordAuth(password: password, authCredential: authCredential)
     
        let addr_id = setupAddrApi.addresses.first?.address_id
        
        let fingerprint = privateKey.fingerprint
        let keylist: [KeyListRaw] = [KeyListRaw.init(fingerprint: fingerprint, primary: 1, flags: 3)]
        
        let jsonKeylist = keylist.json
        
        let signed = try Crypto().signDetached(plainData: jsonKeylist,
                                               privateKey: privateKey,
                                               passphrase: keyPassword)
        
        let signedKeyList = SignedKeyList.init(data: jsonKeylist, signature: signed)
        
        let addressKey = AddressKey.init(addressID: addr_id!,
                                         privateKey: privateKey,
                                         signedKeyList: signedKeyList)
        
        let setupKeyReq = SetupKeyRequest.init(primaryKey: privateKey,
                                               keySalt: keySalt,
                                               addressKeys: [addressKey],
                                               passwordAuth: passwordAuth,
                                               credential: authCredential)
        let setupKeyApi = try await(self.apiService.run(route: setupKeyReq))
        if setupKeyApi.error != nil {
            PMLog.D("signup seupt key error")
        }
    }
    
    /// 1.2 key
    func initAddrKey1_2(password: String, keySalt: String, keyPassword: String, privateKey: String,
                        domain: String, authCredential: AuthCredential? = nil) throws {
        
        //need setup address
        let setupAddrApi: AddressesResponse = try await(self.apiService.run( route: SetupAddressRequest(domain_name: domain, auth: authCredential)))
        
        let passwordAuth = try self.generatPasswordAuth(password: password, authCredential: authCredential)
        
        let addr_id = setupAddrApi.addresses.first?.address_id
        
        let sha256fp = privateKey.SHA256fingerprints
        let fingerprint = privateKey.fingerprint
        let keylist: [KeyListRaw] = [KeyListRaw(fingerprint: fingerprint, sha256fingerprint: sha256fp, primary: 1, flags: 3)]
        let jsonKeylist = keylist.json
        
        let randomToken = try Crypto.random(byte: 32)
        let hexToken = HMAC.hexStringFromData(randomToken) //should be 64 bytes
        
        let signed = try Crypto().signDetached(plainData: jsonKeylist,
                                               privateKey: privateKey,
                                               passphrase: keyPassword)
        let signedKeyList = SignedKeyList.init(data: jsonKeylist, signature: signed)
        
        
        let encToken = try Crypto().encrypt(plainText: hexToken,
                                            publicKey: privateKey.publicKey,
                                            privateKey: privateKey,
                                            passphrase: keyPassword)
        
        let tokenSignature = try Crypto().signDetached(plainData: hexToken,
                                                       privateKey: privateKey,
                                                       passphrase: keyPassword)
        
        let strAddressKey = try Crypto.updatePassphrase(privateKey: privateKey,
                                                        oldPassphrase: keyPassword,
                                                        newPassphrase: hexToken)
        
        let addressKey = AddressKey.init(addressID: addr_id!,
                                         privateKey: strAddressKey,
                                         token: encToken!,
                                         signature: tokenSignature,
                                         signedKeyList: signedKeyList)
        
        let setupKeyReq = SetupKeyRequest.init(primaryKey: privateKey, keySalt: keySalt,
                                               addressKeys: [addressKey], passwordAuth: passwordAuth,
                                               credential: authCredential)
        
        let setupKeyApi = try await(self.apiService.run(route: setupKeyReq))
        if setupKeyApi.error != nil {
            PMLog.D("signup seupt key error")
        }
    }
    
    ///
    /// refactored update mailbox password. can use for mailbox password and single password change. this code need to be in PMAuth module later
    /// - Parameters:
    ///   - currentAuth: custom auth
    ///   - user: userinfo --
    ///   - loginPassword: current login/mbp pwd
    ///   - newPassword: new login/mbp pwd
    ///   - twoFACode: tfa code
    ///   - buildAuth: if need build auth
    ///   - completion: completion
    func updateMailboxPassword(auth currentAuth: AuthCredential,
                               user: UserInfo,
                               loginPassword: String,
                               newPassword: String,
                               twoFACode:String?,
                               buildAuth: Bool, completion: @escaping CompletionBlock) {
        let oldAuthCredential = currentAuth
        let userInfo = user
        let old_password = oldAuthCredential.mailboxpassword
        var _username = "" //oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = userInfo.userAddresses.defaultAddress() {
               _username = addr.email
            }
        }
        guard keymaker.mainKey != nil else {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        /// will look up the address key. if found new schema we will run through new logci
        let isNewSchema = userInfo.newSchema
        if isNewSchema == true {
            /// go through key v1.2 logic
            /// v1.2. update the mailboxpassword or singlelogin password. only need to update userkeys and org keys
            {//asyn
                do {
                    //generat keysalt
                    let new_mpwd_salt : Data = try Crypto.random(byte: 16)
                    //PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                    let new_hashed_mpwd = PasswordUtils.getMailboxPassword(newPassword,
                                                                           salt: new_mpwd_salt)
                    let updated_userlevel_keys = try Crypto.updateKeysPassword(userInfo.userKeys,
                                                                               old_pass: old_password,
                                                                               new_pass: new_hashed_mpwd)
                    var new_org_key : String?
                    //create a key list for key updates
                    if userInfo.role == 2 { //need to get the org keys
                        //check user role if equal 2 try to get the org key.
                        let cur_org_key: OrgKeyResponse = try await(self.apiService.run(route: GetOrgKeys()))
                        if let org_priv_key = cur_org_key.privKey, !org_priv_key.isEmpty {
                            do {
                                new_org_key = try Crypto.updatePassphrase(privateKey: org_priv_key,
                                                                          oldPassphrase: old_password,
                                                                          newPassphrase: new_hashed_mpwd)
                            } catch {
                                //ignore it for now.
                            }
                        }
                    }

                    var authPacket : PasswordAuth?
                    if buildAuth {
                        
                        ///
                        let authModuls: AuthModulusResponse = try await(self.apiService.run(route: AuthModulusRequest(authCredential: oldAuthCredential)))
                        guard let moduls_id = authModuls.ModulusID else {
                            throw UpdatePasswordError.invalidModulusID.error
                        }
                        guard let new_moduls = authModuls.Modulus else {
                            throw UpdatePasswordError.invalidModulus.error
                        }
                        //generat new verifier
                        let new_lpwd_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits

                        guard let auth = try SrpAuthForVerifier(newPassword, new_moduls, new_lpwd_salt) else {
                            throw UpdatePasswordError.cantHashPassword.error
                        }

                        let verifier = try auth.generateVerifier(2048)
                        
                        authPacket = PasswordAuth(modulus_id: moduls_id,
                                                  salt: new_lpwd_salt.encodeBase64(),
                                                  verifer: verifier.encodeBase64())
                    }

                    //start check exsit srp
                    var forceRetry = false
                    var forceRetryVersion = 2
                    repeat {
                        // get auto info
                        let info: AuthInfoResponse = try await(self.apiService.run(route: AuthInfoRequest(username: _username, authCredential: oldAuthCredential)))
                        let authVersion = info.Version
                        guard let modulus = info.Modulus, let ephemeral = info.ServerEphemeral, let salt = info.Salt, let session = info.SRPSession else {
                            throw UpdatePasswordError.invalideAuthInfo.error
                        }

                        if authVersion <= 2 && !forceRetry {
                            forceRetry = true
                            forceRetryVersion = 2
                        }
                        //init api calls
                        let hashVersion = forceRetry ? forceRetryVersion : authVersion
                        guard let auth = try SrpAuth(hashVersion, _username, loginPassword, salt, modulus, ephemeral) else {
                            throw UpdatePasswordError.cantHashPassword.error
                        }
                        let srpClient = try auth.generateProofs(2048)
                        
                        guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                            throw UpdatePasswordError.cantGenerateSRPClient.error
                        }

                        do {
                            let updatePrivkey = UpdatePrivateKeyRequest(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                        clientProof:clientProof.encodeBase64(),
                                                                        SRPSession: session,
                                                                        keySalt: new_mpwd_salt.encodeBase64(),
                                                                        tfaCode: twoFACode,
                                                                        orgKey: new_org_key,
                                                                        userKeys: updated_userlevel_keys,
                                                                        auth: authPacket,
                                                                        authCredential: oldAuthCredential)
                            let update_res = try await(self.apiService.run(route: updatePrivkey))
                            guard update_res.code == 1000 else {
                                throw UpdatePasswordError.default.error
                            }
                            //update local keys
                            userInfo.userKeys = updated_userlevel_keys
                            //userInfo.userAddresses = updated_address_keys
                            oldAuthCredential.udpate(password: new_hashed_mpwd)
                            forceRetry = false
                        } catch let error as NSError {
                            if error.isInternetError() {
                                throw error
                            } else {
                                if forceRetry && forceRetryVersion != 0 {
                                    forceRetryVersion -= 1
                                } else {
                                    throw error
                                }
                            }
                        }

                    } while(forceRetry && forceRetryVersion >= 0)
                    return { completion(nil, nil, nil) } ~> .main
                } catch let error as NSError {
                    Analytics.shared.error(message: .updateMailBoxPassword,
                                           error: error)
                    return { completion(nil, nil, error) } ~> .main
                }
            } ~> .async
            
            
        } else {
            
            {//asyn
                do {
                    //generat keysalt
                    let new_mpwd_salt : Data = try Crypto.random(byte: 16)
                    //PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                    let new_hashed_mpwd = PasswordUtils.getMailboxPassword(newPassword,
                                                                           salt: new_mpwd_salt)

                    let updated_address_keys = try Crypto.updateAddrKeysPassword(userInfo.userAddresses,
                                                                                 old_pass: old_password,
                                                                                 new_pass: new_hashed_mpwd)
                    let updated_userlevel_keys = try Crypto.updateKeysPassword(userInfo.userKeys,
                                                                               old_pass: old_password,
                                                                               new_pass: new_hashed_mpwd)
                    var new_org_key : String?
                    //create a key list for key updates
                    if userInfo.role == 2 { //need to get the org keys
                        //check user role if equal 2 try to get the org key.
                        let cur_org_key: OrgKeyResponse = try await(self.apiService.run(route: GetOrgKeys()))
                        if let org_priv_key = cur_org_key.privKey, !org_priv_key.isEmpty {
                            do {
                                new_org_key = try Crypto.updatePassphrase(privateKey: org_priv_key,
                                                                          oldPassphrase: old_password,
                                                                          newPassphrase: new_hashed_mpwd)
                            } catch {
                                //ignore it for now.
                            }
                        }
                    }

                    var authPacket : PasswordAuth?
                    if buildAuth {
                        
                        ///
                        
                        let authModuls: AuthModulusResponse = try await(self.apiService.run(route: AuthModulusRequest(authCredential: oldAuthCredential)))
                        guard let moduls_id = authModuls.ModulusID else {
                            throw UpdatePasswordError.invalidModulusID.error
                        }
                        guard let new_moduls = authModuls.Modulus else {
                            throw UpdatePasswordError.invalidModulus.error
                        }
                        //generat new verifier
                        let new_lpwd_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits

                        guard let auth = try SrpAuthForVerifier(newPassword, new_moduls, new_lpwd_salt) else {
                            throw UpdatePasswordError.cantHashPassword.error
                        }

                        let verifier = try auth.generateVerifier(2048)
                        authPacket = PasswordAuth(modulus_id: moduls_id,
                                                  salt: new_lpwd_salt.encodeBase64(),
                                                  verifer: verifier.encodeBase64())
                    }

                    //start check exsit srp
                    var forceRetry = false
                    var forceRetryVersion = 2
                    repeat {
                        // get auto info
                        let info: AuthInfoResponse = try await(self.apiService.run(route: AuthInfoRequest(username: _username, authCredential: oldAuthCredential)))
                        let authVersion = info.Version
                        guard let modulus = info.Modulus, let ephemeral = info.ServerEphemeral, let salt = info.Salt, let session = info.SRPSession else {
                            throw UpdatePasswordError.invalideAuthInfo.error
                        }

                        if authVersion <= 2 && !forceRetry {
                            forceRetry = true
                            forceRetryVersion = 2
                        }

                        //init api calls
                        let hashVersion = forceRetry ? forceRetryVersion : authVersion
                        guard let auth = try SrpAuth(hashVersion, _username, loginPassword, salt, modulus, ephemeral) else {
                            throw UpdatePasswordError.cantHashPassword.error
                        }
                        let srpClient = try auth.generateProofs(2048)
                        
                        guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                            throw UpdatePasswordError.cantGenerateSRPClient.error
                        }

                        do {
                            let update_res = try await(self.apiService.run(route: UpdatePrivateKeyRequest(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                                                          clientProof:clientProof.encodeBase64(),
                                                                                                          SRPSession: session,
                                                                                                          keySalt: new_mpwd_salt.encodeBase64(),
                                                                                                          userlevelKeys: updated_userlevel_keys,
                                                                                                          addressKeys: updated_address_keys.toKeys(),
                                                                                                          tfaCode: twoFACode,
                                                                                                          orgKey: new_org_key, userKeys: nil,
                                                                                                          auth: authPacket,
                                                                                                          authCredential: oldAuthCredential)))
                            guard update_res.code == 1000 else {
                                throw UpdatePasswordError.default.error
                            }
                            //update local keys
                            userInfo.userKeys = updated_userlevel_keys
                            userInfo.userAddresses = updated_address_keys
                            oldAuthCredential.udpate(password: new_hashed_mpwd)
                            forceRetry = false
                        } catch let error as NSError {
                            if error.isInternetError() {
                                throw error
                            } else {
                                if forceRetry && forceRetryVersion != 0 {
                                    forceRetryVersion -= 1
                                } else {
                                    throw error
                                }
                            }
                        }

                    } while(forceRetry && forceRetryVersion >= 0)
                    return { completion(nil, nil, nil) } ~> .main
                } catch let error as NSError {
                    Analytics.shared.error(message: .updateMailBoxPassword,
                                           error: error)
                    return { completion(nil, nil, error) } ~> .main
                }
            } ~> .async
            
        }
    }   
}
