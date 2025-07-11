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

import PromiseKit

import ProtonCoreAPIClient
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
@preconcurrency import ProtonCoreDataModel
@preconcurrency import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreKeymaker

/// Stores information related to the user
class UserDataService {
    private let apiService: APIService

    // MARK: - methods
    init(apiService: APIService) {
        self.apiService = apiService
    }

    func fetchUserInfo(auth: AuthCredential? = nil) async -> (UserInfo?, MailSettings) {
        let addressesRequest = GetAddressesRequest()
        async let addressesResponse = await self.apiService.perform(request: addressesRequest, response: AddressesResponse()).1

        let userInfoRequest = GetUserInfoRequest()
        async let userInfoResponse = await self.apiService.perform(request: userInfoRequest, response: GetUserInfoResponse()).1

        let userSettingsRequest = SettingsEndpoint()
        async let userSettingsResponse = await self.apiService.perform(request: userSettingsRequest, response: SettingsResponse()).1

        let mailSettingsRequest = GetMailSettings()
        async let mailSettingsResponse = await self.apiService.perform(request: mailSettingsRequest, response: MailSettingsResponse()).1

        await userInfoResponse.userInfo?.set(addresses: addressesResponse.addresses)
        await userInfoResponse.userInfo?.parse(userSettings: userSettingsResponse.userSettings)
        await userInfoResponse.userInfo?.parse(mailSettings: mailSettingsResponse.mailSettings)

        let mailSettings = try? await MailSettings(dict: mailSettingsResponse.mailSettings ?? [:])

        do {
            try await self.activeUserKeys(userInfo: userInfoResponse.userInfo, auth: auth)
        } catch {
            PMAssertionFailure(error)
        }

        return await (userInfoResponse.userInfo, mailSettings ?? .init())
    }

    func fetchSettings(
        userInfo: UserInfo
    ) -> Promise<(UserInfo, MailSettings)> {
        return async {

            let userSettingsApi = SettingsEndpoint()
            let mailSettingsApi = GetMailSettings()

            let userSettingsRes: SettingsResponse = try AwaitKit.await(self.apiService.run(route: userSettingsApi))
            let mailSettingsRes: MailSettingsResponse = try AwaitKit.await(self.apiService.run(route: mailSettingsApi))

            userInfo.parse(userSettings: userSettingsRes.userSettings)
            userInfo.parse(mailSettings: mailSettingsRes.mailSettings)
            let mailSettings = try? MailSettings(dict: mailSettingsRes.mailSettings ?? [:])

            return (userInfo, mailSettings ?? .init())
        }
    }

    @MainActor
    func activeUserKeys(userInfo: UserInfo?, auth: AuthCredential? = nil) async throws {
        guard let user = userInfo, let pwd = auth?.mailboxpassword else {
            return
        }
        let passphrase = Passphrase(value: pwd)
        for userAddress in user.userAddresses {
            for index in userAddress.keys.indices {
                let key = userAddress.keys[index]
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
                    let activateKeyRequest = ActivateKey(
                        addrID: key.keyID,
                        privKey: new_private_key.value,
                        signedKL: signedKeyList
                    )
                    activateKeyRequest.auth = auth

                    let activateKeyResponse = await self.apiService.perform(request: activateKeyRequest, response: Response()).1
                    if activateKeyResponse.responseCode == 1000 {
                        userAddress.keys[index].privateKey = new_private_key.value
                        userAddress.keys[index].activation = nil
                    }
                }
            }
        }
    }

    func updateAddress(authCredential: AuthCredential,
                       userInfo: UserInfo,
                       addressId: String,
                       displayName: String,
                       signature: String,
                       completion: @escaping (NSError?) -> Void) {
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
        let api = UpdateImageAutoloadSetting(imageType: imageType, setting: setting, authCredential: currentAuth)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo[keyPath: imageType.userInfoKeyPath] = setting.rawValue
            }
            completion(response.error?.toNSError)
        }
    }

    func updateBlockEmailTracking(
        userInfo: UserInfo,
        action: UpdateImageProxy.Action,
        completion: @escaping (NSError?) -> Void
    ) {
        // currently Image Incorporator is not yet supported by any Proton product
        let flag: ProtonCoreDataModel.ImageProxy = .imageProxy

        let request = UpdateImageProxy(flags: flag, action: action)
        apiService.perform(request: request, response: VoidResponse()) { _, response in
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
        let api = SettingUpdateRequest.linkConfirmation(status)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.linkConfirmation = status
            }
            completion(response.error?.toNSError)
        }
    }
    #endif

    // TODO:: refactor newOrders.
    func updateUserDomiansOrder(auth currentAuth: AuthCredential,
                                user: UserInfo,
                                _ email_domains: [Address],
                                newOrder: [String],
                                completion: @escaping (NSError?) -> Void) {
        let authCredential = currentAuth
        let userInfo = user

        let addressOrder = UpdateAddressOrder(adds: newOrder, authCredential: authCredential)
        self.apiService.perform(request: addressOrder, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.userAddresses = email_domains
            }
            completion(response.error?.toNSError)
        }
    }

    func updateNotificationEmail(user: UserInfo,
                                 new_notification_email: String, login_password: String,
                                 twoFACode: String?, completion: @escaping (NSError?) -> Void) {
        let userInfo = user
        //        let old_password = oldAuthCredential.mailboxpassword
        var _username = "" // oldAuthCredential.userName
        if _username.isEmpty {
            if let addr = userInfo.userAddresses.defaultAddress() {
                _username = addr.email
            }
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
                    let modulus = info.modulus
                    let ephemeral = info.serverEphemeral
                    let salt = info.salt
                    let session = info.srpSession

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
                            self.apiService.run(
                                route: SettingUpdateRequest.notificationEmail(
                                    .init(
                                        email: new_notification_email,
                                        clientEphemeral: clientEphemeral.encodeBase64(),
                                        clientProof: clientProof.encodeBase64(),
                                        srpSession: session,
                                        twoFACode: twoFACode
                                    )
                                )
                            )
                        )
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

    func updateNotify(
        user: UserInfo,
        _ isOn: Bool,
        completion: @escaping (NSError?) -> Void
    ) {
        let userInfo = user

        let notifySetting = SettingUpdateRequest.notify(isOn)
        self.apiService.perform(request: notifySetting, response: VoidResponse()) { _, response in
            if response.error == nil {
                userInfo.notify = (isOn ? 1 : 0)
            }
            completion(response.error?.toNSError)
        }
    }

    func updateSignature(_ signature: String, completion: @escaping (NSError?) -> Void) {
        let signatureSetting = SettingUpdateRequest.signature(signature)
        self.apiService.perform(request: signatureSetting, response: VoidResponse()) { _, response in
            completion(response.error?.toNSError)
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
