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


typealias UserInfoBlock = (UserInfo?, String?, NSError?) -> Void

//TODO:: this class need suport mutiple user later
protocol UserDataServiceDelegate {
    func onLogout(animated: Bool)
}

/// Stores information related to the user
class UserDataService : Service, HasLocalStorage {
    typealias UpdatePasswordComplete = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ error: NSError?) -> Void
    
    let apiService : APIService
    var delegate : UserDataServiceDelegate?
    
    struct CoderKey {//Conflict with Key object
        // need to remove and clean
        static let mailboxPassword           = "mailboxPasswordKeyProtectedWithMainKey"
        static let username                  = "usernameKeyProtectedWithMainKey"
        
        static let userInfo                  = "userInfoKeyProtectedWithMainKey"
        static let twoFAStatus               = "twofaKey"
        static let userPasswordMode          = "userPasswordModeKey"
        
        static let roleSwitchCache           = "roleSwitchCache"
        static let defaultSignatureStatus    = "defaultSignatureStatus"
        
        static let firstRunKey = "FirstRunKey"
        
        // new one, check if user logged in already
        static let atLeastOneLoggedIn = "UsersManager.AtLeastoneLoggedIn"
    }
    
    var switchCacheOff: Bool? = SharedCacheBase.getDefault().bool(forKey: CoderKey.roleSwitchCache) {
        didSet {
            SharedCacheBase.getDefault().setValue(switchCacheOff, forKey: CoderKey.roleSwitchCache)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var defaultSignatureStauts: Bool = SharedCacheBase.getDefault().bool(forKey: CoderKey.defaultSignatureStatus) {
        didSet {
            SharedCacheBase.getDefault().setValue(defaultSignatureStauts, forKey: CoderKey.defaultSignatureStatus)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var passwordMode: Int = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode)  {
        didSet {
            SharedCacheBase.getDefault().setValue(passwordMode, forKey: CoderKey.userPasswordMode)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var showDefaultSignature : Bool {
        get {
            return defaultSignatureStauts
        }
        set {
            defaultSignatureStauts = newValue
        }
    }
   
    // MARK: - Public variables
    
    var linkConfirmation: LinkOpeningMode {
        return .confirmationAlert
        //TODO:: fix me
//        return userInfo?.linkConfirmation ?? .confirmationAlert
    }
//
//    var addresses: [Address] { //never be null
//        return userInfo?.userAddresses ?? [Address]()
//    }
//
//    var displayName: String {
//        return (userInfo?.displayName ?? "").decodeHtml()
//    }
//
    var isMailboxPasswordStored: Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }
    
    var isNewUser : Bool = false
    
    var isUserCredentialStored: Bool {
        return isMailboxPasswordStored
//        return SharedCacheBase.getDefault()?.data(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }
    
    func allLoggedout() {
        KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
    }
    
    // MARK: - methods
    init(check : Bool = true, api: APIService) {  //Add interface for data agent //
         self.apiService = api
        if check {
            cleanUpIfFirstRun()
            launchCleanUp()
        }
    }
    
    func fetchUserInfo(auth: AuthCredential? = nil) -> Promise<UserInfo?> {
        return async {
            
            let addrApi = GetAddressesRequest()
            addrApi.auth = auth
            let userApi = GetUserInfoRequest()
            userApi.auth = auth
            let userSettingsApi = GetUserSettings()
            userSettingsApi.auth = auth
            let mailSettingsApi = GetMailSettings()
            mailSettingsApi.auth = auth

            let addrRes: AddressesResponse = try await(self.apiService.run(route: addrApi))
            let userRes: GetUserInfoResponse = try await(self.apiService.run(route: userApi))
            let userSettingsRes: SettingsResponse = try await(self.apiService.run(route: userSettingsApi))
            let mailSettingsRes: MailSettingsResponse = try await(self.apiService.run(route: mailSettingsApi))

            userRes.userInfo?.set(addresses: addrRes.addresses)
            userRes.userInfo?.parse(userSettings: userSettingsRes.userSettings)
            userRes.userInfo?.parse(mailSettings: mailSettingsRes.mailSettings)

            try await(self.activeUserKeys(userInfo: userRes.userInfo, auth: auth) )
            return userRes.userInfo
        }
    }
    
    func activeUserKeys(userInfo: UserInfo?, auth: AuthCredential? = nil) -> Promise<Void> {
        return async {
            guard let user = userInfo, let pwd = auth?.mailboxpassword else {
                return
            }
            let addresses = user.userAddresses
            for addr in addresses {
                for index in 0 ..< addr.keys.count {
                    let key = addr.keys[index]
                    if let activtion = key.activation {
                        guard let token = try activtion.decryptMessage(binKeys: user.userPrivateKeysArray, passphrase: pwd) else {
                            continue
                        }
                        let new_private_key = try Crypto.updatePassphrase(privateKey: key.private_key, oldPassphrase: token, newPassphrase: pwd)
                        let keylist : [[String: Any]] = [[
                            "Fingerprint" :  key.fingerprint,
                            "Primary" : 1,
                            "Flags" : 3
                        ]]
                        let jsonKeylist = keylist.json()
                        let signed = try Crypto().signDetached(plainData: jsonKeylist, privateKey: new_private_key, passphrase: pwd)
                        let signedKeyList : [String: Any] = [
                            "Data" : jsonKeylist,
                            "Signature" : signed
                        ]
                        let api = ActivateKey(addrID: key.key_id, privKey: new_private_key, signedKL: signedKeyList)
                        api.auth = auth
                        
                        do {
                            let activateKeyResponse = try await(self.apiService.run(route: api))
                            if activateKeyResponse.code == 1000 {
                                addr.keys[index].activation = nil
                                addr.keys[index].private_key = new_private_key
                            }
                        } catch let ex {
                            PMLog.D(ex.localizedDescription)
                            //ignore error for now
                        }
                        
                    }
                }
            }
            return
        }
    }
    
    enum MyErrorType : Error {
        case SomeError
    }
    
    static var authResponse: TwoFactorContext? = nil
    func sign(in username: String, password: String, noKeyUser: Bool, twoFACode: String?, checkSalt: Bool = true, faillogout: Bool,
              ask2fa: LoginAsk2FABlock?,
              onError:@escaping LoginErrorBlock,
              onSuccess: @escaping LoginSuccessBlock)
    {
        let completionWrapper: AuthCompleteBlockNew = { mpwd, status, credential, context, userinfo, error in
            DispatchQueue.main.async {
                if status == .ask2FA {
                    UserDataService.authResponse = context
                    ask2fa?()
                } else {
                    UserDataService.authResponse = nil
                    if error == nil {
                        self.passwordMode = mpwd != nil ? 1 : 2
                        onSuccess(mpwd, credential, userinfo)
                    } else {
                        if faillogout {
                            self.signOut(true)
                        }
                        onError(error!)
                    }
                }
            }
        }

        if let authRes = UserDataService.authResponse {
            apiService.confirm2FA(twoFACode ?? "", password: password, context: authRes, completion: completionWrapper)
        } else {
            apiService.authenticate(username: username, password: password, noKey: noKeyUser, completion: completionWrapper)
        }
    }

    
    func clean() {
        clearAll()
    }
    
    func cleanUserInfo() {
        
    }
    
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            // TODO: logout one user and remove its stuff from local storage
            self.signOutFromServer()
            seal.fulfill_()
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        // TODO: logout all users and clear local storage
        return Promise()
    }
    
    func signOutFromServer() {
        let api = AuthDeleteRequest()
        self.apiService.exec(route: api) { (task, response) in
            // probably we want to notify user the session will seem active on website in case of error
        }
    }
    
    func signOut(_ animated: Bool) {
        sharedVMService.signOut()
        NotificationCenter.default.post(name: Notification.Name.didSignOut, object: self)
        clearAll()
        delegate?.onLogout(animated: animated)
    }
    
    func signOutAfterSignUp() {
        sharedVMService.signOut()
        NotificationCenter.default.post(name: Notification.Name.didSignOut, object: self)
        clearAll()
    }
    
    @available(*, deprecated, message: "account wise display name, i don't think we are using it any more. double check and remvoe it")
    func updateDisplayName(auth currentAuth: AuthCredential,
                           user: UserInfo,
                           displayName: String, completion: UserInfoBlock?) {
        let authCredential = currentAuth
        let userInfo = user
        guard let _ = keymaker.mainKey else
        {
            completion?(nil, nil, NSError.lockError())
            return
        }
        
        let new_displayName = displayName.trim()
        let api = UpdateDisplayNameRequest(displayName: new_displayName, authCredential: authCredential)
        self.apiService.exec(route: api) { task, response in
            if response.error == nil {
                userInfo.displayName = new_displayName
            }
            completion?(userInfo, nil, response.error)
        }
    }
    
    func updateAddress(auth currentAuth: AuthCredential,
                       user: UserInfo,
                       addressId: String, displayName: String, signature: String, completion: UserInfoBlock?) {
        let authCredential = currentAuth
        let userInfo = user
        guard let _ = keymaker.mainKey else
        {
            completion?(nil, nil, NSError.lockError())
            return
        }
        
        let new_displayName = displayName.trim()
        let new_signature = signature.trim()
        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature, authCredential: authCredential)
        self.apiService.exec(route: api) { task, response in
            if response.error == nil {
                let addresses = userInfo.userAddresses
                for addr in addresses {
                    if addr.address_id == addressId {
                        addr.display_name = new_displayName
                        addr.signature = new_signature
                        break
                    }
                }
                userInfo.userAddresses = addresses
            }
            completion?(userInfo, nil, response.error)
        }
    }
    
    func updateAutoLoadImage(auth currentAuth: AuthCredential,
                             user: UserInfo,
                             remote status: Bool, completion: @escaping UserInfoBlock) {
        
        let authCredential = currentAuth
        let userInfo = user
        guard let _ = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        var newStatus = userInfo.showImages
        if status {
            newStatus.insert(.remote)
        } else {
            newStatus.remove(.remote)
        }
        
        let api = UpdateShowImages(status: newStatus.rawValue, authCredential: authCredential)
        self.apiService.exec(route: api) { (task, response) in
            if response.error == nil {
                userInfo.showImages = newStatus
            }
            completion(userInfo, nil, response.error)
        }
    }
    
    #if !APP_EXTENSION
    func updateLinkConfirmation(auth currentAuth: AuthCredential,
                                user: UserInfo,
                                _ status: LinkOpeningMode, completion: @escaping UserInfoBlock) {
        let authCredential = currentAuth
        let userInfo = user
        guard let _ = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        let api = UpdateLinkConfirmation(status: status, authCredential: authCredential)
        self.apiService.exec(route: api) { (task, response) in
            if response.error == nil {
                userInfo.linkConfirmation = status
            }
            completion(userInfo, nil, response.error)
        }
    }
    #endif

    func updatePassword(auth currentAuth: AuthCredential,
                        user: UserInfo,
                        login_password: String,
                        new_password: String,
                        twoFACode:String?,
                        completion: @escaping CompletionBlock) {
        let oldAuthCredential = currentAuth
        var _username = "" //oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = user.userAddresses.defaultAddress() {
               _username = addr.email
            }
        }

        {//async
            do {
                //generate new pwd and verifier
                let authModuls: AuthModulusResponse = try await(self.apiService.run(route: AuthModulusRequest(authCredential: oldAuthCredential)))
                guard let moduls_id = authModuls.ModulusID else {
                    throw UpdatePasswordError.invalidModulusID.error
                }
                guard let new_moduls = authModuls.Modulus else {
                    throw UpdatePasswordError.invalidModulus.error
                }
                //generat new verifier
                let new_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits

                guard let auth = try SrpAuthForVerifier(new_password, new_moduls, new_salt) else {
                    throw UpdatePasswordError.cantHashPassword.error
                }
                let verifier = try auth.generateVerifier(2048)

                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2

                repeat {
                    // get auto info
                    let info: AuthInfoResponse = try await(self.apiService.run(route: AuthInfoRequest(username: _username, authCredential: oldAuthCredential)))
                    let authVersion = info.Version
                    guard let modulus = info.Modulus,
                        let ephemeral = info.ServerEphemeral, let salt = info.Salt,
                        let session = info.SRPSession else {
                            throw UpdatePasswordError.invalideAuthInfo.error
                    }

                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }

                    //init api calls
                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let auth = try SrpAuth(hashVersion, _username, login_password, salt, modulus, ephemeral) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }

                    let srpClient = try auth.generateProofs(2048)
                    guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }

                    do {
                        let updatePwd_res = try await(self.apiService.run(route: UpdateLoginPassword(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                                                     clientProof: clientProof.encodeBase64(),
                                                                                                     SRPSession: session,
                                                                                                     modulusID: moduls_id,
                                                                                                     salt: new_salt.encodeBase64(),
                                                                                                     verifer: verifier.encodeBase64(),
                                                                                                     tfaCode: twoFACode,
                                                                                                     authCredential: oldAuthCredential)))
                        if updatePwd_res.code == 1000 {
                            forceRetry = false
                        } else {
                            throw UpdatePasswordError.default.error
                        }
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
                Analytics.shared.error(message: .updateLoginPassword,
                                       error: error)
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
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
    
    //TODO:: refactor newOrders. 
    func updateUserDomiansOrder(auth currentAuth: AuthCredential,
                                user: UserInfo,
                                _ email_domains: [PMCommon.Address], newOrder : [String], completion: @escaping CompletionBlock) {
        
        let authCredential = currentAuth
        let userInfo = user

        guard let _ = keymaker.mainKey else {
            completion(nil, nil, NSError.lockError())
            return
        }

        let addressOrder = UpdateAddressOrder(adds: newOrder, authCredential: authCredential)
        self.apiService.exec(route: addressOrder) { task, response in
            if response.error == nil {
                userInfo.userAddresses = email_domains
            }
            completion(task, nil, nil)
        }
    }
    
    func updateUserSwipeAction(auth currentAuth: AuthCredential,
                               userInfo: UserInfo,
                               isLeft : Bool,
                               action: MessageSwipeAction,
                               completion: @escaping CompletionBlock) {
        let api : Request = isLeft ? UpdateSwiftLeftAction(action: action, authCredential: currentAuth) : UpdateSwiftRightAction(action: action, authCredential: currentAuth)
        self.apiService.exec(route: api) { task, response in
            if response.error == nil {
                userInfo.swipeLeft = isLeft ? action.rawValue : userInfo.swipeLeft
                userInfo.swipeRight = isLeft ? userInfo.swipeRight : action.rawValue
            }
            completion(task, nil, nil)
        }
    }
    
    func updateNotificationEmail(auth currentAuth: AuthCredential,
                                 user: UserInfo,
                                 new_notification_email: String, login_password : String,
                                 twoFACode: String?, completion: @escaping CompletionBlock) {
        let oldAuthCredential = currentAuth
        let userInfo = user
//        let old_password = oldAuthCredential.mailboxpassword
        var _username = "" //oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = userInfo.userAddresses.defaultAddress() {
               _username = addr.email
            }
        }

        guard let _ = keymaker.mainKey else {
            completion(nil, nil, NSError.lockError())
            return
        }

        {//asyn
            do {
                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2

                repeat {
                    // get auto info
                    let info: AuthInfoResponse = try await(self.apiService.run(route: AuthInfoRequest(username: _username, authCredential: oldAuthCredential)))
                    let authVersion = info.Version
                    guard let modulus = info.Modulus, let ephemeral = info.ServerEphemeral, let salt = info.Salt, let session = info.SRPSession else {
                        throw UpdateNotificationEmailError.invalideAuthInfo.error
                    }

                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }

                    //init api calls
                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let auth = try SrpAuth(hashVersion, _username, login_password, salt, modulus, ephemeral) else {
                        throw UpdateNotificationEmailError.cantHashPassword.error
                    }

                    let srpClient = try auth.generateProofs(2048)
                    guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }

                    do {
                        let updatetNotifyEmailRes = try await(self.apiService.run(route: UpdateNotificationEmail(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                                                                 clientProof: clientProof.encodeBase64(),
                                                                                                                 sRPSession: session,
                                                                                                                 notificationEmail: new_notification_email,
                                                                                                                 tfaCode: twoFACode,
                                                                                                                 authCredential: oldAuthCredential)))
                        if updatetNotifyEmailRes.code == 1000 {
                            userInfo.notificationEmail = new_notification_email
                            forceRetry = false
                        } else {
                            throw UpdateNotificationEmailError.default.error
                        }
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
                Analytics.shared.error(message: .updateLoginPassword,
                                       error: error)
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
    func updateNotify(auth currentAuth: AuthCredential,
                      user: UserInfo,
                      _ isOn: Bool, completion: @escaping CompletionBlock) {
        let oldAuthCredential = currentAuth
        let userInfo = user

        guard let _ = keymaker.mainKey else {
            completion(nil, nil, NSError.lockError())
            return
        }
        let notifySetting = UpdateNotify(notify: isOn ? 1 : 0, authCredential: oldAuthCredential)
        self.apiService.exec(route: notifySetting) { task, response in
            if response.error == nil {
                userInfo.notify = (isOn ? 1 : 0)
            }
            completion(task, nil, response.error)
        }
    }
    
    func updateSignature(auth currentAuth: AuthCredential,
                         user: UserInfo,
                         _ signature: String, completion: @escaping CompletionBlock) {
        guard let _ = keymaker.mainKey else {
            completion(nil, nil, NSError.lockError())
            return
        }

        let signatureSetting = UpdateSignature(signature: signature, authCredential: currentAuth)
        self.apiService.exec(route: signatureSetting) { (task, response) in
            completion(task, nil, response.error)
        }
    }
    
    // MARK: - Private methods
    
    func cleanUpIfFirstRun() {
        #if !APP_EXTENSION
        if AppCache.isFirstRun() {
            clearAll()
            SharedCacheBase.getDefault().set(Date(), forKey: CoderKey.firstRunKey)
            SharedCacheBase.getDefault().synchronize()
        }
        #endif
    }
    
    func clearAll() {
        allLoggedout()
       //mailboxPassword = nil
        passwordMode = 2
    }
    
    
//    func completionForUserInfo(_ completion: UserInfoBlock?) -> CompletionBlock {
//        return { task, response, error in
//            if error == nil {
//                self.fetchUserInfo().done { (userInfo) in
//                    
////                    self.fetchUserInfo(completion)
//                }.catch { error in
//                    
////                    self.fetchUserInfo(completion)
//                }
//                
//            } else {
//                completion?(nil, nil, error)
//            }
//        }
//    }
    
    func launchCleanUp() {
        if !self.isUserCredentialStored {
            passwordMode = 2
        }
    }
    
    //Login callback blocks
    typealias LoginAsk2FABlock = () -> Void
    typealias LoginErrorBlock = (_ error: NSError) -> Void
    typealias LoginSuccessBlock = (_ mpwd: String?, _ auth: AuthCredential?, _ userinfo: UserInfo?) -> Void
}




extension AppCache {
    static func inject(userInfo: UserInfo, into userDataService: UserDataService) {
        //userDataService.userInfo = userInfo
    }
    
    static func inject(username: String, into userDataService: UserDataService) {
//        userDataService.username = username
    }
}



extension PMCommon.UserInfo {
    var userPrivateKeys : Data {
        var out = Data()
        var error : NSError?
        for key in userKeys {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var userPrivateKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in userKeys {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }

}
