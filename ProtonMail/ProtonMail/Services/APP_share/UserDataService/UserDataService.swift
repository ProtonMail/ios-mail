//
//  UserDataService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PromiseKit
import GoLibs
import OpenPGP
import ProtonCore_APIClient
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_Keymaker

// TODO:: this class need suport mutiple user later
protocol UserDataServiceDelegate {
    func onLogout()
}

/// Stores information related to the user
class UserDataService: Service {
    let apiService: APIService
    var delegate: UserDataServiceDelegate?
    private let userDataServiceQueue = DispatchQueue.init(label: "UserDataServiceQueue", qos: .utility)

    struct CoderKey {// Conflict with Key object
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

    var passwordMode: Int = SharedCacheBase.getDefault().integer(forKey: CoderKey.userPasswordMode) {
        didSet {
            SharedCacheBase.getDefault().setValue(passwordMode, forKey: CoderKey.userPasswordMode)
            SharedCacheBase.getDefault().synchronize()
        }
    }

    // MARK: - Public variables

    var isMailboxPasswordStored: Bool {
        return KeychainWrapper.keychain.string(forKey: CoderKey.atLeastOneLoggedIn) != nil
    }

    var isUserCredentialStored: Bool {
        return isMailboxPasswordStored
    }

    func allLoggedout() {
        KeychainWrapper.keychain.remove(forKey: CoderKey.atLeastOneLoggedIn)
    }

    // MARK: - methods
    init(check: Bool = true, api: APIService) {  // Add interface for data agent
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

            let addrRes: AddressesResponse = try `await`(self.apiService.run(route: addrApi))
            let userRes: GetUserInfoResponse = try `await`(self.apiService.run(route: userApi))
            let userSettingsRes: SettingsResponse = try `await`(self.apiService.run(route: userSettingsApi))
            let mailSettingsRes: MailSettingsResponse = try `await`(self.apiService.run(route: mailSettingsApi))

            userRes.userInfo?.set(addresses: addrRes.addresses)
            userRes.userInfo?.parse(userSettings: userSettingsRes.userSettings)
            userRes.userInfo?.parse(mailSettings: mailSettingsRes.mailSettings)

            try `await`(self.activeUserKeys(userInfo: userRes.userInfo, auth: auth) )
            return userRes.userInfo
        }
    }

    func fetchSettings(userInfo: UserInfo, auth: AuthCredential) -> Promise<UserInfo> {
        return async {

            let userSettingsApi = GetUserSettings()
            userSettingsApi.auth = auth
            let mailSettingsApi = GetMailSettings()
            mailSettingsApi.auth = auth

            let userSettingsRes: SettingsResponse = try AwaitKit.await(self.apiService.run(route: userSettingsApi))
            let mailSettingsRes: MailSettingsResponse = try AwaitKit.await(self.apiService.run(route: mailSettingsApi))

            userInfo.parse(userSettings: userSettingsRes.userSettings)
            userInfo.parse(mailSettings: mailSettingsRes.mailSettings)

            return userInfo
        }
    }

    func activeUserKeys(userInfo: UserInfo?, auth: AuthCredential? = nil) -> Promise<Void> {
        return async {
            guard let user = userInfo, let pwd = auth?.mailboxpassword else {
                return
            }
            let passphrase = Passphrase(value: pwd)
            for addr in user.userAddresses {
                for index in addr.keys.indices {
                    let key = addr.keys[index]
                    if let activation = key.activation {
                        let decryptionKeys = user.userPrivateKeys.map {
                            DecryptionKey(privateKey: $0, passphrase: passphrase)
                        }
                        let token: String = try Decryptor.decrypt(
                            decryptionKeys: decryptionKeys,
                            encrypted: ArmoredMessage(value: activation)
                        )
                        let new_private_key = try Crypto.updatePassphrase(
                            privateKey: ArmoredKey(value: key.privateKey),
                            oldPassphrase: Passphrase(value: token),
                            newPassphrase: passphrase
                        )
                        let keylist: [[String: Any]] = [[
                            "Fingerprint": key.fingerprint,
                            "Primary": 1,
                            "Flags": 3
                        ]]
                        let jsonKeylist = keylist.json()
                        let signed = try Sign.signDetached(
                            signingKey: SigningKey(privateKey: new_private_key, passphrase: passphrase),
                            plainText: jsonKeylist
                        )
                        let signedKeyList: [String: Any] = [
                            "Data": jsonKeylist,
                            "Signature": signed
                        ]
                        let api = ActivateKey(
                            addrID: key.keyID,
                            privKey: new_private_key.value,
                            signedKL: signedKeyList
                        )
                        api.auth = auth

                        do {
                            let activateKeyResponse = try `await`(self.apiService.run(route: api))
                            if activateKeyResponse.responseCode == 1000 {
                                addr.keys[index].privateKey = new_private_key.value
                                addr.keys[index].activation = nil
                            }
                        } catch {
                        }
                    }
                }
            }
        }
    }

    static func cleanUpAll() -> Promise<Void> {
        // TODO: logout all users and clear local storage
        return Promise()
    }

    func signOut() {
#if APP_EXTENSION
#else
        sharedVMService.signOut()
#endif

        if !ProcessInfo.isRunningUnitTests {
            NotificationCenter.default.post(name: Notification.Name.didSignOut, object: self)
        }
        clearAll()
        delegate?.onLogout()
    }

    func updateAddress(authCredential: AuthCredential,
                       userInfo: UserInfo,
                       addressId: String,
                       displayName: String,
                       signature: String,
                       completion: @escaping (NSError?) -> Void) {
        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }

        let new_displayName = displayName.trim()
        let new_signature = signature.trim()
        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature, authCredential: authCredential)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.userAddresses = userInfo.userAddresses.map { addr in
                    guard addr.addressID == addressId else { return addr }
                    return addr.withUpdated(displayName: new_displayName, signature: new_signature)
                }
            }
            completion(response.error?.toNSError)
        }
    }

    #if !APP_EXTENSION
    func updateImageAutoloadSetting(
        currentAuth: AuthCredential,
        userInfo: UserInfo,
        imageType: UpdateImageAutoloadSetting.ImageType,
        setting: UpdateImageAutoloadSetting.Setting,
        completion: @escaping (NSError?) -> Void
    ) {
        guard keymaker.mainKey(by: RandomPinProtection.randomPin) != nil else {
            completion(NSError.lockError())
            return
        }

        let api = UpdateImageAutoloadSetting(imageType: imageType, setting: setting, authCredential: currentAuth)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo[keyPath: imageType.userInfoKeyPath] = setting.rawValue
            }
            completion(response.error?.toNSError)
        }
    }

    func updateBlockEmailTracking(
        authCredential: AuthCredential,
        userInfo: UserInfo,
        action: UpdateImageProxy.Action,
        completion: @escaping (NSError?) -> Void
    ) {
        guard keymaker.mainKey(by: RandomPinProtection.randomPin) != nil else {
            completion(NSError.lockError())
            return
        }

        // currently Image Incorporator is not yet supported by any Proton product
        let flag: ProtonCore_DataModel.ImageProxy = .imageProxy

        let api = UpdateImageProxy(flags: flag, action: action, authCredential: authCredential)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { task, response in
            if response.error == nil {
                var newStatus = userInfo.imageProxy
                switch action {
                case .add:
                    newStatus.insert(flag)
                case .remove:
                    newStatus.remove(flag)
                }
                userInfo.imageProxy = newStatus
            }
            completion(response.error?.toNSError)
        }
    }
    #endif

    func updateDelaySeconds(userInfo: UserInfo,
                            delaySeconds: Int,
                            completion: @escaping (Error?) -> Void) {
        let userInfo = userInfo
        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }

        let request = UpdateDelaySecondsRequest(delaySeconds: delaySeconds)
        self.apiService.perform(request: request, response: Response()) { _, response in
            if response.error == nil {
                userInfo.delaySendSeconds = delaySeconds
            }
            completion(response.error?.toNSError)
        }
    }

    #if !APP_EXTENSION
    func updateLinkConfirmation(auth currentAuth: AuthCredential,
                                user: UserInfo,
                                _ status: LinkOpeningMode, completion: @escaping (NSError?) -> Void) {
        let authCredential = currentAuth
        let userInfo = user
        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }
        let api = UpdateLinkConfirmation(status: status, authCredential: authCredential)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.linkConfirmation = status
            }
            completion(response.error?.toNSError)
        }
    }
    #endif

    func updatePassword(auth currentAuth: AuthCredential,
                        user: UserInfo,
                        login_password: String,
                        new_password: Passphrase,
                        twoFACode: String?,
                        completion: @escaping (NSError?) -> Void) {
        let oldAuthCredential = currentAuth
        var _username = "" // oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = user.userAddresses.defaultAddress() {
                _username = addr.email
            }
        }

        {// async
            do {
                // generate new pwd and verifier
                let authModuls: AuthModulusResponse = try `await`(self.apiService.run(route: AuthAPI.Router.modulus))
                guard let moduls_id = authModuls.ModulusID else {
                    throw UpdatePasswordError.invalidModulusID.error
                }
                guard let new_moduls = authModuls.Modulus else {
                    throw UpdatePasswordError.invalidModulus.error
                }
                // generat new verifier
                let new_salt: Data = PMNOpenPgp.randomBits(80) // for the login password needs to set 80 bits

                guard let auth = try SrpAuthForVerifier(new_password, new_moduls, new_salt) else {
                    throw UpdatePasswordError.cantHashPassword.error
                }
                let verifier = try auth.generateVerifier(2048)

                // start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2

                repeat {
                    // get auto info

                    let info: AuthInfoResponse = try `await`(self.apiService.run(route: AuthAPI.Router.info(username: _username)))
                    let authVersion = info.version
                    guard let modulus = info.modulus,
                          let ephemeral = info.serverEphemeral, let salt = info.salt,
                          let session = info.srpSession else {
                        throw UpdatePasswordError.invalideAuthInfo.error
                    }

                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }

                    // init api calls
                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let auth = try SrpAuth(hashVersion, _username, login_password, salt, modulus, ephemeral) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }

                    let srpClient = try auth.generateProofs(2048)
                    guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }

                    do {
                        let updatePwd_res = try `await`(
                            self.apiService.run(route: UpdateLoginPassword(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                           clientProof: clientProof.encodeBase64(),
                                                                           SRPSession: session,
                                                                           modulusID: moduls_id,
                                                                           salt: new_salt.encodeBase64(),
                                                                           verifer: verifier.encodeBase64(),
                                                                           tfaCode: twoFACode,
                                                                           authCredential: oldAuthCredential)))
                        if updatePwd_res.responseCode == 1000 {
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
                return { completion(nil) } ~> .main
            } catch let error as NSError {
                return { completion(error) } ~> .main
            }
        } ~> .async
    }

    func updateMailboxPassword(auth currentAuth: AuthCredential,
                               user: UserInfo,
                               loginPassword: String,
                               newPassword: Passphrase,
                               twoFACode: String?,
                               buildAuth: Bool,
                               completion: @escaping (NSError?) -> Void) {
        let oldAuthCredential = currentAuth
        let userInfo = user
        let old_password = Passphrase(value: oldAuthCredential.mailboxpassword)
        var _username = "" // oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = userInfo.userAddresses.defaultAddress() {
                _username = addr.email
            }
        }
        guard keymaker.mainKey(by: RandomPinProtection.randomPin) != nil else {
            completion(NSError.lockError())
            return
        }

        userDataServiceQueue.async {
            do {
                let resultOfKeyUpdate: UserDataServiceKeyHelper.UpdatedKeyResult
                let helper = UserDataServiceKeyHelper()

                if userInfo.isKeyV2 {
                    /// go through key v1.2 logic
                    /// v1.2. update the mailboxpassword or single-login password. We only need to update userkeys and org keys.
                    resultOfKeyUpdate = try helper.updatePasswordV2(userKeys: userInfo.userKeys,
                                                                        oldPassword: old_password,
                                                                        newPassword: newPassword)
                } else {
                    resultOfKeyUpdate = try helper.updatePassword(userKeys: userInfo.userKeys,
                                                                  addressKeys: userInfo.userAddresses,
                                                                  oldPassword: old_password,
                                                                  newPassword: newPassword)
                }

                var new_org_key: ArmoredKey?
                // check user role if equal 2 try to get the org key.
                if userInfo.role == 2 {
                    let cur_org_key: OrgKeyResponse = try `await`(self.apiService.run(route: GetOrgKeys()))
                    if let org_priv_key = cur_org_key.privKey, !org_priv_key.isEmpty {
                        do {
                            new_org_key = try Crypto
                                .updatePassphrase(privateKey: ArmoredKey(value: org_priv_key),
                                                  oldPassphrase: old_password,
                                                  newPassphrase: resultOfKeyUpdate.hashedNewPassword)
                        } catch {
                            // ignore it for now.
                        }
                    }
                }

                var authPacket: PasswordAuth?
                if buildAuth {
                    let authModuls: AuthModulusResponse = try `await`(self.apiService.run(route: AuthAPI.Router.modulus))
                    guard let moduls_id = authModuls.ModulusID else {
                        throw UpdatePasswordError.invalidModulusID.error
                    }
                    guard let new_moduls = authModuls.Modulus else {
                        throw UpdatePasswordError.invalidModulus.error
                    }
                    // generat new verifier
                    let new_lpwd_salt: Data = PMNOpenPgp.randomBits(80) // for the login password needs to set 80 bits

                    guard let auth = try SrpAuthForVerifier(newPassword, new_moduls, new_lpwd_salt) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }

                    let verifier = try auth.generateVerifier(2048)

                    authPacket = PasswordAuth(modulus_id: moduls_id,
                                              salt: new_lpwd_salt.encodeBase64(),
                                              verifer: verifier.encodeBase64())
                }

                // start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2
                repeat {
                    // get auto info
                    let info: AuthInfoResponse = try `await`(self.apiService.run(route: AuthAPI.Router.info(username: _username)))
                    let authVersion = info.version
                    guard let modulus = info.modulus, let ephemeral = info.serverEphemeral, let salt = info.salt, let session = info.srpSession else {
                        throw UpdatePasswordError.invalideAuthInfo.error
                    }

                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }

                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let auth = try SrpAuth(hashVersion, _username, loginPassword, salt, modulus, ephemeral) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }
                    let srpClient = try auth.generateProofs(2048)

                    guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }

                    do {
                        let request: UpdatePrivateKeyRequest
                        if userInfo.isKeyV2 {
                            request = UpdatePrivateKeyRequest(
                                clientEphemeral: clientEphemeral.encodeBase64(),
                                clientProof: clientProof.encodeBase64(),
                                SRPSession: session,
                                keySalt: resultOfKeyUpdate.saltOfNewPassword.encodeBase64(),
                                tfaCode: twoFACode,
                                orgKey: new_org_key?.value,
                                userKeys: resultOfKeyUpdate.updatedUserKeys,
                                auth: authPacket,
                                authCredential: oldAuthCredential
                            )
                        } else {
                            request = UpdatePrivateKeyRequest(
                                clientEphemeral: clientEphemeral.encodeBase64(),
                                clientProof: clientProof.encodeBase64(),
                                SRPSession: session,
                                keySalt: resultOfKeyUpdate.saltOfNewPassword.encodeBase64(),
                                userlevelKeys: resultOfKeyUpdate.updatedUserKeys,
                                addressKeys: resultOfKeyUpdate.updatedAddresses?.toKeys() ?? [],
                                tfaCode: twoFACode,
                                orgKey: new_org_key?.value,
                                userKeys: resultOfKeyUpdate.updatedUserKeys,
                                auth: authPacket,
                                authCredential: oldAuthCredential
                            )
                        }

                        let update_res = try `await`(self.apiService.run(route: request))
                        guard update_res.responseCode == 1000 else {
                            throw UpdatePasswordError.default.error
                        }

                        // update local keys and passphrase
                        if userInfo.isKeyV2 {
                            userInfo.userKeys = resultOfKeyUpdate.updatedUserKeys + resultOfKeyUpdate.originalUserKeys
                        } else {
                            userInfo.userKeys = resultOfKeyUpdate.updatedUserKeys + resultOfKeyUpdate.originalUserKeys
                            userInfo.userAddresses = resultOfKeyUpdate.updatedAddresses ?? []
                        }
                        oldAuthCredential.udpate(password: resultOfKeyUpdate.hashedNewPassword.value)

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
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    // TODO:: refactor newOrders.
    func updateUserDomiansOrder(auth currentAuth: AuthCredential,
                                user: UserInfo,
                                _ email_domains: [Address],
                                newOrder: [String],
                                completion: @escaping (NSError?) -> Void) {
        let authCredential = currentAuth
        let userInfo = user

        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }

        let addressOrder = UpdateAddressOrder(adds: newOrder, authCredential: authCredential)
        self.apiService.perform(request: addressOrder, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.userAddresses = email_domains
            }
            completion(response.error?.toNSError)
        }
    }

    func updateNotificationEmail(auth currentAuth: AuthCredential,
                                 user: UserInfo,
                                 new_notification_email: String, login_password: String,
                                 twoFACode: String?, completion: @escaping (NSError?) -> Void) {
        let oldAuthCredential = currentAuth
        let userInfo = user
        //        let old_password = oldAuthCredential.mailboxpassword
        var _username = "" // oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = userInfo.userAddresses.defaultAddress() {
                _username = addr.email
            }
        }

        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }

        {// asyn
            do {
                // start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2

                repeat {
                    // get auto info
                    let info: AuthInfoResponse = try `await`(self.apiService.run(route: AuthAPI.Router.info(username: _username)))
                    let authVersion = info.version
                    guard let modulus = info.modulus, let ephemeral = info.serverEphemeral, let salt = info.salt, let session = info.srpSession else {
                        throw UpdateNotificationEmailError.invalideAuthInfo.error
                    }

                    if authVersion <= 2 && !forceRetry {
                        forceRetry = true
                        forceRetryVersion = 2
                    }

                    // init api calls
                    let hashVersion = forceRetry ? forceRetryVersion : authVersion
                    guard let auth = try SrpAuth(hashVersion, _username, login_password, salt, modulus, ephemeral) else {
                        throw UpdateNotificationEmailError.cantHashPassword.error
                    }

                    let srpClient = try auth.generateProofs(2048)
                    guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }

                    do {
                        let updatetNotifyEmailRes = try `await`(
                            self.apiService.run(route: UpdateNotificationEmail(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                               clientProof: clientProof.encodeBase64(),
                                                                               sRPSession: session,
                                                                               notificationEmail: new_notification_email,
                                                                               tfaCode: twoFACode,
                                                                               authCredential: oldAuthCredential)))
                        if updatetNotifyEmailRes.responseCode == 1000 {
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
                return { completion(nil) } ~> .main
            } catch let error as NSError {
                return { completion(error) } ~> .main
            }
        } ~> .async
    }

    func updateNotify(auth currentAuth: AuthCredential,
                      user: UserInfo,
                      _ isOn: Bool, completion: @escaping (NSError?) -> Void) {
        let oldAuthCredential = currentAuth
        let userInfo = user

        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }
        let notifySetting = UpdateNotify(notify: isOn ? 1 : 0, authCredential: oldAuthCredential)
        self.apiService.perform(request: notifySetting, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.notify = (isOn ? 1 : 0)
            }
            completion(response.error?.toNSError)
        }
    }

    func updateSignature(auth currentAuth: AuthCredential,
                         _ signature: String, completion: @escaping (NSError?) -> Void) {
        guard let _ = keymaker.mainKey(by: RandomPinProtection.randomPin) else {
            completion(NSError.lockError())
            return
        }

        let signatureSetting = UpdateSignature(signature: signature, authCredential: currentAuth)
        self.apiService.perform(request: signatureSetting, response: VoidResponse()) { _, response in
            completion(response.error?.toNSError)
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
        // mailboxPassword = nil
        passwordMode = 2
    }

    func launchCleanUp() {
        if !self.isUserCredentialStored {
            passwordMode = 2
        }
    }

    func fetchUserAddresses(completion: ((Swift.Result<AddressesResponse, Error>) -> Void)?) {
        let req = GetAddressesRequest()
        apiService.perform(request: req, response: AddressesResponse()) { _, res in
            if let error = res.error {
                completion?(.failure(error))
            } else {
                completion?(.success(res))
            }
        }
    }
}

extension UserInfo {
    var userPrivateKeys: [ArmoredKey] {
        userKeys.toArmoredPrivateKeys
    }

}
