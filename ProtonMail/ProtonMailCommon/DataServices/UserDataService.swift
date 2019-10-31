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
import Keymaker
import Crypto

//TODO:: this class need suport mutiple user later
protocol UserDataServiceDelegate {
    func onLogout(animated: Bool)
}

/// Stores information related to the user
class UserDataService : Service {
    enum RuntimeError : String, Error, CustomErrorVar {
        case no_address = "Can't find address key"
        case no_user = "Can't find user info"
        var code: Int {
            get {
                return -1001000
            }
        }
        
        var desc: String {
            get {
                return self.rawValue
            }
        }
        
        var reason: String {
            get {
                return self.rawValue
            }
        }
    }
    
    typealias CompletionBlock = APIService.CompletionBlock
    typealias UserInfoBlock = APIService.UserInfoBlock
    
    //Login callback blocks
    typealias LoginAsk2FABlock = () -> Void
    typealias LoginErrorBlock = (_ error: NSError) -> Void
    typealias LoginSuccessBlock = (_ mpwd: String?) -> Void
    
    var delegate : UserDataServiceDelegate?
    
    struct CoderKey {//Conflict with Key object
        static let mailboxPassword           = "mailboxPasswordKeyProtectedWithMainKey"
        static let username                  = "usernameKeyProtectedWithMainKey"
        
        static let userInfo                  = "userInfoKeyProtectedWithMainKey"
        static let twoFAStatus               = "twofaKey"
        static let userPasswordMode          = "userPasswordModeKey"
        
        static let roleSwitchCache           = "roleSwitchCache"
        static let defaultSignatureStatus    = "defaultSignatureStatus"
        
        static let firstRunKey = "FirstRunKey"
    }
    
    // MARK: - Private variables
    fileprivate(set) var userInfo: UserInfo? {
        get {
            guard let mainKey = keymaker.mainKey,
                let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.userInfo) else
            {
                return nil
            }
            
            let locked = Locked<UserInfo>(encryptedValue: cypherData)
            return try? locked.unlock(with: mainKey)
        }
        set {
            self.saveUserInfo(newValue)
        }
    }
    private func saveUserInfo(_ newValue: UserInfo?, protectedBy cachedKey: Keymaker.Key? = nil) {
        guard let newValue = newValue else {
            SharedCacheBase.getDefault()?.removeObject(forKey: CoderKey.userInfo)
            return
        }
        guard let mainKey = cachedKey ?? keymaker.mainKey,
            let locked = try? Locked<UserInfo>(clearValue: newValue, with: mainKey) else
        {
            return
        }
        SharedCacheBase.getDefault()?.set(locked.encryptedValue, forKey: CoderKey.userInfo)
        SharedCacheBase.getDefault().synchronize()
    }
    
    //TODO::Fix later fileprivate(set)
    fileprivate(set) var username: String? {
        get {
            guard let mainKey = keymaker.mainKey,
                let cypherData = SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) else
            {
                return nil
            }
            
            let locked = Locked<String>(encryptedValue: cypherData)
            return try? locked.unlock(with: mainKey)
        }
        set {
            guard let newValue = newValue else {
                SharedCacheBase.getDefault()?.removeObject(forKey: CoderKey.username)
                return
            }
            guard let mainKey = keymaker.mainKey,
                let locked = try? Locked<String>(clearValue: newValue, with: mainKey) else
            {
                return
            }
            SharedCacheBase.getDefault()?.set(locked.encryptedValue, forKey: CoderKey.username)
            SharedCacheBase.getDefault().synchronize()
        }
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
    
    var twoFactorStatus: Int = SharedCacheBase.getDefault().integer(forKey: CoderKey.twoFAStatus)  {
        didSet {
            SharedCacheBase.getDefault().setValue(twoFactorStatus, forKey: CoderKey.twoFAStatus)
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
    
    var showMobileSignature : Bool {
        get {
            #if Enterprise
                let isEnterprise = true
            #else
                let isEnterprise = false
            #endif
            
            let role = userInfo?.role ?? 0
            if role > 0 || isEnterprise {
                return switchCacheOff == false
            } else {
                switchCacheOff = false
                return true
            } }
        set {
            switchCacheOff = (newValue == false)
        }
    }
    
    var mobileSignature : String {
        get {
            #if Enterprise
                let isEnterprise = true
            #else
                let isEnterprise = false
            #endif
            let role = userInfo?.role ?? 0
            if role > 0 || isEnterprise {
                return userCachedStatus.mobileSignature
            } else {
                userCachedStatus.resetMobileSignature()
                return userCachedStatus.mobileSignature
            }
        }
        set {
            userCachedStatus.mobileSignature = newValue
        }
    }
    
    var usedSpace: Int64 {
        return userInfo?.usedSpace ?? 0
    }
    
    var autoLoadRemoteImages: Bool {
        return userInfo?.autoShowRemote ?? false
    }
    
    var firstUserPublicKey: String? {
        if let keys = userInfo?.userKeys, keys.count > 0 {
            for k in keys {
                return k.publicKey
            }
        }
        return nil
    }

    func getAddressPrivKey(address_id : String) -> String {
        let addr = addresses.indexOfAddress(address_id) ?? addresses.defaultSendAddress()
        return addr?.keys.first?.private_key ?? ""
    }
    
    func getAddressKey(address_id : String) -> Key? {
        let addr = addresses.indexOfAddress(address_id) ?? addresses.defaultSendAddress()
        return addr?.keys.first
    }
    
    var newSchema : Bool {
        for k in addressKeys {
            if k.newSchema {
                return true
            }
        }
        return false
    }
    
    @available(iOS, message: "migrate to new key schema")
    var addressPrivateKeys : Data {
        var out = Data()
        var error : NSError?
        for addr in addresses {
            for key in addr.keys {
                if let privK = ArmorUnarmor(key.private_key, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
    
    var addressKeys : [Key] {
        return self.userInfo?.addressKeys ?? [Key]()
    }
    
    var userPrivateKeys : Data {
        return self.userInfo?.userPrivateKeys ?? Data()
    }
    
    // MARK: - Public variables
    
    var defaultEmail : String {
        if let addr = addresses.defaultAddress() {
            return addr.email
        }
        return ""
    }
    
    var defaultDisplayName : String {
        if let addr = addresses.defaultAddress() {
            return addr.display_name
        }
        return displayName
    }
    
    var swiftLeft : MessageSwipeAction {
        return userInfo?.swipeLeftAction ?? .archive
    }
    
    var swiftRight : MessageSwipeAction {
        return userInfo?.swipeRightAction ?? .trash
    }
    
    var linkConfirmation: LinkOpeningMode {
        return userInfo?.linkConfirmation ?? .confirmationAlert
    }
    
    var addresses: [Address] { //never be null
        return userInfo?.userAddresses ?? [Address]()
    }

    var displayName: String {
        return (userInfo?.displayName ?? "").decodeHtml()
    }
    
    var isMailboxPasswordStored: Bool {
        return KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword) != nil
    }
    
    var isNewUser : Bool = false
    
    var isUserCredentialStored: Bool {
        return SharedCacheBase.getDefault()?.data(forKey: CoderKey.username) != nil
    }
    
    /// Value is only stored in the keychain
    var mailboxPassword: String? {
        get {
            guard let cypherBits = KeychainWrapper.keychain.data(forKey: CoderKey.mailboxPassword),
                let key = keymaker.mainKey else
            {
                return nil
            }
            let locked = Locked<String>(encryptedValue: cypherBits)
            return try? locked.unlock(with: key)
        }
        set {
            self.saveMailboxPassword(newValue)
        }
    }
    private func saveMailboxPassword(_ newValue: String?, protectedBy cachedKey: Keymaker.Key? = nil) {
        guard let newValue = newValue else {
            KeychainWrapper.keychain.remove(forKey: CoderKey.mailboxPassword)
            return
        }
        guard let key = cachedKey ?? keymaker.mainKey,
            let locked = try? Locked<String>(clearValue: newValue, with: key) else
        {
            KeychainWrapper.keychain.remove(forKey: CoderKey.mailboxPassword)
            return
        }
        
        KeychainWrapper.keychain.set(locked.encryptedValue, forKey: CoderKey.mailboxPassword)
    }
    
    var maxSpace: Int64 {
        return userInfo?.maxSpace ?? 0
    }
    
    var notificationEmail: String {
        return userInfo?.notificationEmail ?? ""
    }
    
    var notify: Bool {
        return (userInfo?.notify ?? 0 ) == 1
    }
    
    var userDefaultSignature: String {
        return (userInfo?.defaultSignature ?? "").ln2br()
    }
    
    var isSet : Bool {
        return userInfo != nil
    }
    
    // MARK: - methods
    init(check : Bool = true) {
        if check {
            cleanUpIfFirstRun()
            launchCleanUp()
        }
    }
    
    func fetchUserInfo() -> Promise<UserInfo?> {
        return async {
            
            let addrApi = GetAddressesRequest()
            let userApi = GetUserInfoRequest()
            let userSettingsApi = GetUserSettings()
            let mailSettingsApi = GetMailSettings()
            
            let addrRes = try await(addrApi.run())
            let userRes = try await(userApi.run())
            let userSettingsRes = try await(userSettingsApi.run())
            let mailSettingsRes = try await(mailSettingsApi.run())
            
            userRes.userInfo?.set(addresses: addrRes.addresses)
            userRes.userInfo?.parse(userSettings: userSettingsRes.userSettings)
            userRes.userInfo?.parse(mailSettings: mailSettingsRes.mailSettings)
            
            self.userInfo = userRes.userInfo
            
            try await(self.activeUserKeys() )
            
            return self.userInfo
        }
    }
    
    func activeUserKeys() -> Promise<Void> {
        return async {
            guard let user = self.userInfo, let pwd = self.mailboxPassword else {
                return
            }
            let addresses = user.userAddresses
            for addr in addresses {
                for index in 0 ..< addr.keys.count {
                    let key = addr.keys[index]
                    if let activtion = key.activation {
                        guard let token = try activtion.decryptMessage(binKeys: self.userPrivateKeys, passphrase: pwd) else {
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
                        let userSettingsRes = try await(api.run())
                        if userSettingsRes.code == 1000 {
                            addr.keys[index].activation = nil
                            addr.keys[index].private_key = new_private_key
                            self.userInfo = user
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
    //
    func updateFromEvents(userInfo: [String : Any]?) {
        if let userData = userInfo {
            let newUserInfo = UserInfo(response: userData)
            if let user = self.userInfo {
                user.set(userinfo: newUserInfo)
                self.userInfo = user
            }
        }
    }
    //
    func updateFromEvents(userSettings: [String : Any]?) {
        if let user = self.userInfo {
            user.parse(userSettings: userSettings)
            self.userInfo = user
        }
    }
    func updateFromEvents(mailSettings: [String : Any]?) {
        if let user = self.userInfo {
            user.parse(mailSettings: mailSettings)
            self.userInfo = user
        }
    }
    
    func update(usedSpace: Int64) {
        if let user = self.userInfo {
            user.usedSpace = usedSpace
            self.userInfo = user
        }
    }

    func setFromEvents(address: Address) {
        if let user = self.userInfo {
            if let index = user.userAddresses.firstIndex(where: { $0.address_id == address.address_id }) {
                user.userAddresses.remove(at: index)
            }
            user.userAddresses.append(address)
            user.userAddresses.sort(by: { (v1, v2) -> Bool in
                return v1.order < v2.order
            })
            self.userInfo = user
        }
    }
    
    func deleteFromEvents(addressID: String) {
        if let user = self.userInfo {
            if let index = user.userAddresses.firstIndex(where: { $0.address_id == addressID }) {
                user.userAddresses.remove(at: index)
                self.userInfo = user
            }
        }
    }
    
    func isMailboxPasswordValid(_ password: String, privateKey : String) -> Bool {
        return privateKey.check(passphrase: password)
    }
    
    func setMailboxPassword(_ password: String, keysalt: String?) {
        mailboxPassword = password
    }
    
    var authResponse: AuthResponse? = nil
    func signIn(_ username: String, password: String, twoFACode: String?, checkSalt: Bool = true,
                ask2fa: @escaping LoginAsk2FABlock,
                onError:@escaping LoginErrorBlock,
                onSuccess: @escaping LoginSuccessBlock) {
        
        
        let completionWrapper: APIService.AuthCompleteBlock = { task, mpwd, status, res, error in
            if status == .ask2FA {
                self.twoFactorStatus = 1
                self.authResponse = res
                ask2fa()
            } else {
                self.authResponse = nil
                if error == nil {
                    self.username = username
                    self.passwordMode = mpwd != nil ? 1 : 2
                    self.twoFactorStatus = NSNumber(value: twoFACode != nil).intValue
                    onSuccess(mpwd)
                } else {
                    self.twoFactorStatus = 0
                    self.signOut(true)
                    onError(error!)
                }
            }
        }
        
        if let authRes = authResponse {
            sharedAPIService.auth2fa(res: authRes, password: password, twoFACode: twoFACode, checkSalt: checkSalt, completion: completionWrapper)
        } else {
            // will use standard authCredential
            sharedAPIService.auth(username, password: password, twoFACode: twoFACode, authCredential: nil, checkSalt: checkSalt, completion: completionWrapper)
        }
    }

    
    func clean() {
        clearAll()
        clearAuthToken()
    }
    
    func cleanUserInfo() {
        
    }
    
    func signOut(_ animated: Bool) {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), let token = authCredential.token, !token.isEmpty {
            let api = AuthDeleteRequest()
            api.authCredential = authCredential
            api.call { (task, response, hasError) in
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name.didSignOut, object: self)
        clearAll()
        clearAuthToken()
        delegate?.onLogout(animated: animated)
    }
    
    func signOutAfterSignUp() {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), let token = authCredential.token, !token.isEmpty {
            let api = AuthDeleteRequest()
            api.authCredential = authCredential
            api.call { (task, response, hasError) in
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name.didSignOut, object: self)
        clearAll()
        clearAuthToken()
    }
    
    @available(*, deprecated, message: "account wise display name, i don't think we are using it any more. double check and remvoe it")
    func updateDisplayName(_ displayName: String, completion: UserInfoBlock?) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion?(nil, nil, NSError.lockError())
            return
        }
        
        let new_displayName = displayName.trim()
        let api = UpdateDisplayNameRequest(displayName: new_displayName, authCredential: authCredential)
        api.call() { task, response, hasError in
            if !hasError {
                userInfo.displayName = new_displayName
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAddress(_ addressId: String, displayName: String, signature: String, completion: UserInfoBlock?) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion?(nil, nil, NSError.lockError())
            return
        }
        
        let new_displayName = displayName.trim()
        let new_signature = signature.trim()
        
        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature, authCredential: authCredential)
        api.call() { task, response, hasError in
            if !hasError {
                let addresses = userInfo.userAddresses
                for addr in addresses {
                    if addr.address_id == addressId {
                        addr.display_name = new_displayName
                        addr.signature = new_signature
                        break
                    }
                }
                userInfo.userAddresses = addresses
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAutoLoadImage(remote status: Bool, completion: @escaping UserInfoBlock) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
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
        api.call { (task, response, hasError) in
            if !hasError {
                userInfo.showImages = newStatus
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion(self.userInfo, nil, response?.error)
        }
    }

    func updateShowArchiveButton(status: Bool, completion: @escaping UserInfoBlock) {
        guard let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }

        // TODO: save settings server-side
        DispatchQueue.main.async {
            userInfo.showArchiveButton = status
            self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            completion(self.userInfo, nil, nil)
        }
    }

    #if !APP_EXTENSION
    func updateLinkConfirmation(_ status: LinkOpeningMode, completion: @escaping UserInfoBlock) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        let api = UpdateLinkConfirmation(status: status, authCredential: authCredential)
        api.call { (task, response, hasError) in
            if !hasError {
                userInfo.linkConfirmation = status
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion(self.userInfo, nil, response?.error)
        }
    }
    #endif

    func updatePassword(_ login_password: String, new_password: String, twoFACode:String?, completion: @escaping CompletionBlock) {
        guard let oldAuthCredential = AuthCredential.fetchFromKeychain(),
            let _username = self.username else {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        {//asyn
            do {
                //generate new pwd and verifier
                let authModuls = try AuthModulusRequest(authCredential: oldAuthCredential).syncCall()
                guard let moduls_id = authModuls?.ModulusID else {
                    throw UpdatePasswordError.invalidModulusID.error
                }
                guard let new_moduls = authModuls?.Modulus else {
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
                    let info = try AuthInfoRequest(username: _username, authCredential: oldAuthCredential).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus,
                        let ephemeral = info?.ServerEphemeral, let salt = info?.Salt,
                        let session = info?.SRPSession else {
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
                        let updatePwd = try UpdateLoginPassword(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                clientProof: clientProof.encodeBase64(),
                                                                SRPSession: session,
                                                                modulusID: moduls_id,
                                                                salt: new_salt.encodeBase64(),
                                                                verifer: verifier.encodeBase64(),
                                                                tfaCode: twoFACode,
                                                                authCredential: oldAuthCredential).syncCall()
                        if updatePwd?.code == 1000 {
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
                error.upload(toAnalytics: "UpdateLoginPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
    func updateMailboxPassword(_ login_password: String, new_password: String,
                               twoFACode:String?, buildAuth: Bool, completion: @escaping CompletionBlock) {
        guard let oldAuthCredential = AuthCredential.fetchFromKeychain(),
            let user_info = self.userInfo,
            let old_password = self.mailboxPassword,
            let _username = self.username,
            let cachedMainKey = keymaker.mainKey else {
                
            completion(nil, nil, NSError.lockError())
            return
        }
        
        {//asyn
            do {
                //generat keysalt
                let new_mpwd_salt : Data = try Crypto.random(byte: 16)
                //PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                let new_hashed_mpwd = PasswordUtils.getMailboxPassword(new_password,
                                                                       salt: new_mpwd_salt)
                
                let updated_address_keys = try Crypto.updateAddrKeysPassword(user_info.userAddresses,
                                                                             old_pass: old_password,
                                                                             new_pass: new_hashed_mpwd)
                let updated_userlevel_keys = try Crypto.updateKeysPassword(user_info.userKeys,
                                                                                   old_pass: old_password,
                                                                                   new_pass: new_hashed_mpwd)
                var new_org_key : String?
                //create a key list for key updates
                if user_info.role == 2 { //need to get the org keys
                    //check user role if equal 2 try to get the org key.
                    let cur_org_key = try GetOrgKeys().syncCall()
                    if let org_priv_key = cur_org_key?.privKey, !org_priv_key.isEmpty {
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
                    let authModuls = try AuthModulusRequest(authCredential: oldAuthCredential).syncCall()
                    guard let moduls_id = authModuls?.ModulusID else {
                        throw UpdatePasswordError.invalidModulusID.error
                    }
                    guard let new_moduls = authModuls?.Modulus else {
                        throw UpdatePasswordError.invalidModulus.error
                    }
                    //generat new verifier
                    let new_lpwd_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                    
                    guard let auth = try SrpAuthForVerifier(new_password, new_moduls, new_lpwd_salt) else {
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
                    let info = try AuthInfoRequest(username: _username, authCredential: oldAuthCredential).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
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
                        let update_res = try UpdatePrivateKeyRequest(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                     clientProof:clientProof.encodeBase64(),
                                                                     SRPSession: session,
                                                                     keySalt: new_mpwd_salt.encodeBase64(),
                                                                     userlevelKeys: updated_userlevel_keys,
                                                                     addressKeys: updated_address_keys.toKeys(),
                                                                     tfaCode: twoFACode,
                                                                     orgKey: new_org_key,
                                                                     auth: authPacket,
                                                                     authCredential: oldAuthCredential).syncCall()
                        guard update_res?.code == 1000 else {
                            throw UpdatePasswordError.default.error
                        }
                        //update local keys
                        user_info.userKeys = updated_userlevel_keys
                        user_info.userAddresses = updated_address_keys
                        self.saveUserInfo(user_info, protectedBy: cachedMainKey)
                        self.saveMailboxPassword(new_hashed_mpwd, protectedBy: cachedMainKey)
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
                error.upload(toAnalytics: "UpdateMailBoxPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
        
    }
    
    //TODO:: refactor newOrders. 
    func updateUserDomiansOrder(_ email_domains: [Address], newOrder : [String], completion: @escaping CompletionBlock) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        let addressOrder = UpdateAddressOrder(adds: newOrder, authCredential: authCredential)
        addressOrder.call() { task, response, hasError in
            if !hasError {
                userInfo.userAddresses = email_domains
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion(task, nil, nil)
        }
    }
    
    func updateUserSwipeAction(_ isLeft : Bool , action: MessageSwipeAction, completion: @escaping CompletionBlock) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        
        let api = isLeft ? UpdateSwiftLeftAction(action: action, authCredential: authCredential) : UpdateSwiftRightAction(action: action, authCredential: authCredential)
        api.call() { task, response, hasError in
            if !hasError {
                userInfo.swipeLeft = isLeft ? action.rawValue : userInfo.swipeLeft
                userInfo.swipeRight = isLeft ? userInfo.swipeRight : action.rawValue
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion(task, nil, nil)
        }
    }
    
    func updateNotificationEmail(_ new_notification_email: String, login_password : String,
                                 twoFACode: String?, completion: @escaping CompletionBlock) {
        guard let oldAuthCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let _username = self.username,
            let cachedMainKey = keymaker.mainKey else {
                
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
                    let info = try AuthInfoRequest(username: _username, authCredential: oldAuthCredential).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
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
                        let updatetNotifyEmailRes = try UpdateNotificationEmail(clientEphemeral: clientEphemeral.encodeBase64(),
                                                                                clientProof: clientProof.encodeBase64(),
                                                                                sRPSession: session,
                                                                                notificationEmail: new_notification_email,
                                                                                tfaCode: twoFACode,
                                                                                authCredential: oldAuthCredential).syncCall()
                        if updatetNotifyEmailRes?.code == 1000 {
                            userInfo.notificationEmail = new_notification_email
                            self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
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
                error.upload(toAnalytics: "UpdateLoginPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
    func updateNotify(_ isOn: Bool, completion: @escaping CompletionBlock) {
        guard let authCredential = AuthCredential.fetchFromKeychain(),
            let userInfo = self.userInfo,
            let cachedMainKey = keymaker.mainKey else
        {
            completion(nil, nil, NSError.lockError())
            return
        }
        let notifySetting = UpdateNotify(notify: isOn ? 1 : 0, authCredential: authCredential)
        notifySetting.call() { task, response, hasError in
            if !hasError {
                userInfo.notify = (isOn ? 1 : 0)
                self.saveUserInfo(userInfo, protectedBy: cachedMainKey)
            }
            completion(task, nil, response?.error)
        }
    }
    
    func updateSignature(_ signature: String, completion: UserInfoBlock?) {
        guard let authCredential = AuthCredential.fetchFromKeychain() else {
            completion?(nil, nil, NSError.lockError())
            return
        }
        sharedAPIService.settingUpdateSignature(signature, authCredential: authCredential, completion: completionForUserInfo(completion))
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
        username = nil
        mailboxPassword = nil
        userInfo = nil
        twoFactorStatus = 0
        passwordMode = 2
        keymaker.wipeMainKey()
        FileManager.default.cleanTemporaryDirectory()
        
        // some tests are messed up without tmp folder, so let's keep it for consistency
        #if targetEnvironment(simulator)
        try? FileManager.default.createDirectory(at: FileManager.default.temporaryDirectoryUrl, withIntermediateDirectories: true, attributes:
                nil)
        #endif
    }
    
    func clearAuthToken() {
        AuthCredential.clearFromKeychain()
    }
    
    func completionForUserInfo(_ completion: UserInfoBlock?) -> CompletionBlock {
        return { task, response, error in
            if error == nil {
                self.fetchUserInfo().done { (userInfo) in
                    
//                    self.fetchUserInfo(completion)
                }.catch { error in
                    
//                    self.fetchUserInfo(completion)
                }
                
            } else {
                completion?(nil, nil, error)
            }
        }
    }
    
    func launchCleanUp() {
        if !self.isUserCredentialStored {
            twoFactorStatus = 0
            passwordMode = 2
        }
    }
    
    /**
     - Returns: true if the user is a paid user, otherwise return false
     */
    func isPaidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role,
            role > 0 {
            return true
        }
        return false
    }
}

extension AppCache {
    static func inject(userInfo: UserInfo, into userDataService: UserDataService) {
        userDataService.userInfo = userInfo
    }
    
    static func inject(username: String, into userDataService: UserDataService) {
        userDataService.username = username
    }
}



extension UserInfo {
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
    
    var addressKeys : [Key] {
        var out = [Key]()
        for addr in userAddresses {
            for key in addr.keys {
                out.append(key)
            }
        }
        return out
    }
}
