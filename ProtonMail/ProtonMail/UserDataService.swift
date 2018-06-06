//
//  UserDataService.swift
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
import AwaitKit
import PromiseKit
import Pm


//TODO:: this class need suport mutiple user later
protocol UserDataServiceDelegate {
    func onLogout(animated: Bool)
}

/// Stores information related to the user
class UserDataService {
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
    
    struct Key {
        static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
        static let isRememberUser            = "isRememberUserKey"
        static let mailboxPassword           = "mailboxPasswordKey"
        static let username                  = "usernameKey"
        static let password                  = "passwordKey"
        static let userInfo                  = "userInfoKey"
        static let twoFAStatus               = "twofaKey"
        static let userPasswordMode          = "userPasswordModeKey"
        
        static let roleSwitchCache           = "roleSwitchCache"
        static let defaultSignatureStatus    = "defaultSignatureStatus"
    }
    
    // MARK: - Private variables
    //TODO::Fix later fileprivate(set)
    fileprivate(set) var userInfo: UserInfo? = SharedCacheBase.getDefault().customObjectForKey(Key.userInfo) as? UserInfo {
        didSet {
            SharedCacheBase.getDefault().setCustomValue(userInfo, forKey: Key.userInfo)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    //TODO::Fix later fileprivate(set)
    fileprivate(set) var username: String? = SharedCacheBase.getDefault().string(forKey: Key.username) {
        didSet {
            SharedCacheBase.getDefault().setValue(username, forKey: Key.username)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    // Value is only stored in the keychain
    var password: String? {
        get {
            do {
                let savedPwd = sharedKeychain.keychain().string(forKey: Key.password)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.password)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.password)
                sharedKeychain.keychain().setString(nv, forKey: Key.password)
            }catch {
            }
        }
    }
    
    var switchCacheOff: Bool? = SharedCacheBase.getDefault().bool(forKey: Key.roleSwitchCache) {
        didSet {
            SharedCacheBase.getDefault().setValue(switchCacheOff, forKey: Key.roleSwitchCache)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var defaultSignatureStauts: Bool = SharedCacheBase.getDefault().bool(forKey: Key.defaultSignatureStatus) {
        didSet {
            SharedCacheBase.getDefault().setValue(defaultSignatureStauts, forKey: Key.defaultSignatureStatus)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var twoFactorStatus: Int = SharedCacheBase.getDefault().integer(forKey: Key.twoFAStatus)  {
        didSet {
            SharedCacheBase.getDefault().setValue(twoFactorStatus, forKey: Key.twoFAStatus)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var passwordMode: Int = SharedCacheBase.getDefault().integer(forKey: Key.userPasswordMode)  {
        didSet {
            SharedCacheBase.getDefault().setValue(passwordMode, forKey: Key.userPasswordMode)
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
            
            if userInfo?.role > 0 || isEnterprise {
                return switchCacheOff == false //TODO:: need test this part
            } else {
                switchCacheOff = false
                return true;
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
            
            if userInfo?.role > 0 || isEnterprise {
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
    
    var showShowImageView: Bool {
        return userInfo?.showImages == 0
    }
    
    var firstUserPublicKey: String? {
        if let keys = userInfo?.userKeys, keys.count > 0 {
            for k in keys {
                return k.public_key
            }
        }
        return nil
    }
    
    func getAddressPrivKey(address_id : String) -> String {
        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
        return addr?.keys.first?.private_key ?? ""
    }
    
    var addressPrivKeys : Data {
        var out = Data()
        var error : NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = PmUnArmor(key.private_key, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
    
    var userPrivKeys : Data {
        var out = Data()
        var error : NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = PmUnArmor(key.private_key, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
    
    // MARK: - Public variables
    
    var defaultEmail : String {
        if let addr = userAddresses.defaultAddress() {
            return addr.email;
        }
        return "";
    }
    
    var defaultDisplayName : String {
        if let addr = userAddresses.defaultAddress() {
            return addr.display_name;
        }
        return displayName;
    }
    
    var swiftLeft : MessageSwipeAction! {
        get {
            return MessageSwipeAction(rawValue: userInfo?.swipeLeft ?? 3) ?? .archive
        }
    }
    
    var swiftRight : MessageSwipeAction! {
        get {
            return MessageSwipeAction(rawValue: userInfo?.swipeRight ?? 0) ?? .trash
        }
    }
    
    var userAddresses: [Address] { //never be null
        return userInfo?.userAddresses ?? [Address]()
    }
    
    var displayName: String {
        return (userInfo?.displayName ?? "").decodeHtml()
    }
    
    var isMailboxPasswordStored: Bool {
        
        isMailboxPWDOk = mailboxPassword != nil;
        
        return mailboxPassword != nil
    }
    
    var isRememberMailboxPassword: Bool = SharedCacheBase.getDefault().bool(forKey: Key.isRememberMailboxPassword) {
        didSet {
            SharedCacheBase.getDefault().set(isRememberMailboxPassword, forKey: Key.isRememberMailboxPassword)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var isRememberUser: Bool = SharedCacheBase.getDefault().bool(forKey: Key.isRememberUser) {
        didSet {
            SharedCacheBase.getDefault().set(isRememberUser, forKey: Key.isRememberUser)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    var isSignedIn: Bool = false
    var isNewUser : Bool = false
    var isMailboxPWDOk: Bool = false
    
    var isUserCredentialStored: Bool {
        return username != nil && password != nil && isRememberUser
    }
    
    /// Value is only stored in the keychain
    var mailboxPassword: String? {
        get {
            do {
                let savedPwd = sharedKeychain.keychain().string(forKey: Key.mailboxPassword)
                return try savedPwd?.decrypt(withPwd: "$Proton$" + Key.mailboxPassword)
            }catch {
                return nil
            }
        }
        set {
            do {
                let nv = try newValue?.encrypt(withPwd: "$Proton$" + Key.mailboxPassword)
                sharedKeychain.keychain().setString(nv, forKey: Key.mailboxPassword)
            }catch {
            }
        }
    }
    
    var maxSpace: Int64 {
        return userInfo?.maxSpace ?? 0
    }
    
    var notificationEmail: String {
        return userInfo?.notificationEmail ?? ""
    }
    
    var notify: Bool {
        return (userInfo?.notify ?? 0 ) == 1;
    }
    
    var signature: String {
        return (userInfo?.signature ?? "").ln2br()
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
            
            let addrRes = try await(addrApi.run())
            let userRes = try await(userApi.run())
            
            userRes.userInfo?.setAddresses(addresses: addrRes.addresses)
            self.userInfo = userRes.userInfo
//            if let addresses = self.userInfo?.userAddresses.toPMNAddresses() {
//                sharedOpenPGP.setAddresses(addresses);
//            }
            return self.userInfo
        }
    }
    
    func updateUserInfoFromEventLog (_ userInfo : UserInfo){
        self.userInfo = userInfo
    }
    
    func isMailboxPasswordValid(_ password: String, privateKey : String) -> Bool {
        return privateKey.check(passphrase: password)
    }
    
    func setMailboxPassword(_ password: String, keysalt: String?, isRemembered: Bool) {
        mailboxPassword = password
        isRememberMailboxPassword = isRemembered
        self.isMailboxPWDOk = true;
    }
    
    func isPasswordValid(_ password: String?) -> Bool {
        return self.password == password
    }
    
    func signIn(_ username: String, password: String, twoFACode: String?, ask2fa: @escaping LoginAsk2FABlock, onError:@escaping LoginErrorBlock, onSuccess: @escaping LoginSuccessBlock) {
        sharedAPIService.auth(username, password: password, twoFACode: twoFACode) { task, mpwd, status, error in
            if status == .ask2FA {
                self.twoFactorStatus = 1
                ask2fa()
            } else {
                if error == nil {
                    self.isSignedIn = true
                    self.username = username
                    self.password = password
                    self.isRememberUser = true
                    self.passwordMode = mpwd != nil ? 1 : 2
                    
                    onSuccess(mpwd)
                } else {
                    self.twoFactorStatus = 0
                    self.signOut(true)
                    onError(error!)
                }
            }
        }
    }
    
    func clean() {
        clearAll()
        clearAuthToken()
    }
    
    func signOut(_ animated: Bool) {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), let token = authCredential.token, !token.isEmpty {
            AuthDeleteRequest().call { (task, response, hasError) in
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignOut), object: self)
        clearAll()
        clearAuthToken()
        delegate?.onLogout(animated: animated)
        //(UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: animated)
    }
    
    func signOutAfterSignUp() {
        sharedVMService.signOut()
        if let authCredential = AuthCredential.fetchFromKeychain(), let token = authCredential.token, !token.isEmpty {
            AuthDeleteRequest().call { (task, response, hasError) in
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignOut), object: self)
        clearAll()
        clearAuthToken()
    }
    
    func updateDisplayName(_ displayName: String, completion: UserInfoBlock?) {
        let new_displayName = displayName.trim()
        let api = UpdateDisplayNameRequest(displayName: new_displayName)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.displayName = new_displayName
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAddress(_ addressId: String, displayName: String, signature: String, completion: UserInfoBlock?) {
        let new_displayName = displayName.trim()
        let new_signature = signature.trim()
        
        let api = UpdateAddressRequest(id: addressId, displayName: new_displayName, signature: new_signature)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    let addresses = userInfo.userAddresses
                    for addr in addresses {
                        if addr.address_id == addressId {
                            addr.display_name = new_displayName
                            addr.signature = new_signature
                            break
                        }
                    }
                    userInfo.userAddresses = addresses
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updateAutoLoadImage(_ status : Int, completion: UserInfoBlock?) {
        let api = UpdateShowImagesRequest(status: status)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.showImages = status
                    self.userInfo = userInfo
                }
            }
            completion?(self.userInfo, nil, nil)
        }
    }
    
    func updatePassword(_ login_password: String, new_password: String, twoFACode:String?, completion: @escaping CompletionBlock) {
        {//asyn
            do {
                //generate new pwd and verifier
                guard let _username = self.username else {
                    throw UpdatePasswordError.invalidUserName.error
                }
                let authModuls = try AuthModulusRequest().syncCall()
                guard let moduls_id = authModuls?.ModulusID else {
                    throw UpdatePasswordError.invalidModulusID.error
                }
                guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                    throw UpdatePasswordError.invalidModulus.error
                }
                //generat new verifier
                let new_decodedModulus : Data = new_encodedModulus.decodeBase64()
                let new_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(new_password, salt: new_salt, modulus: new_decodedModulus) else {
                    throw UpdatePasswordError.cantHashPassword.error
                }
                
                guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                    throw UpdatePasswordError.cantGenerateVerifier.error
                }
                
                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2
                
                repeat {
                    // get auto info
                    let info = try AuthInfoRequest<AuthInfoResponse>(username: _username).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
                        throw UpdatePasswordError.invalideAuthInfo.error
                    }
                    guard let encodedModulus = try modulus.getSignature() else {
                        throw UpdatePasswordError.invalideAuthInfo.error
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
                    guard let hashedPassword = PasswordUtils.getHashedPwd(hashVersion, password: login_password , username: _username, decodedSalt: decodedSalt, decodedModulus: decodedModulus) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }
                    
                    guard let srpClient = try generateSrpProofs(2048, modulus: decodedModulus, serverEphemeral: serverEphemeral, hashedPassword: hashedPassword), srpClient.isValid() == true else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }
                    
                    do {
                        let updatePwd = try UpdateLoginPassword(clientEphemeral: srpClient.clientEphemeral.encodeBase64(),
                                                                clientProof: srpClient.clientProof.encodeBase64(),
                                                                SRPSession: session,
                                                                modulusID: moduls_id,
                                                                salt: new_salt.encodeBase64(),
                                                                verifer: verifier.encodeBase64(),
                                                                tfaCode: twoFACode).syncCall()
                        if updatePwd?.code == 1000 {
                            self.password = new_password
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
                error.upload(toFabric: "UpdateLoginPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
    func updateMailboxPassword(_ login_password: String, new_password: String, twoFACode:String?, buildAuth: Bool, completion: @escaping CompletionBlock) {
        {//asyn
            do {
                guard let _username = self.username else {
                    throw UpdatePasswordError.invalidUserName.error
                }
                
                guard let user_info = self.userInfo else {
                    throw UpdatePasswordError.default.error
                }
                
                guard let old_password = self.mailboxPassword else {
                    throw UpdatePasswordError.currentPasswordWrong.error
                }

                //generat keysalt
                let new_mpwd_salt : Data = PmRandomTokenWith(16, nil) //PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                let new_hashed_mpwd = PasswordUtils.getMailboxPassword(new_password, salt: new_mpwd_salt)
                

                let updated_address_keys = try PmOpenPGP.updateAddrKeysPassword(user_info.userAddresses, old_pass: old_password, new_pass: new_hashed_mpwd)
                let updated_userlevel_keys = try PmOpenPGP.updateKeysPassword(user_info.userKeys, old_pass: old_password, new_pass: new_hashed_mpwd)

                var new_org_key : String?
                //create a key list for key updates
                if user_info.role == 2 { //need to get the org keys
                    //check user role if equal 2 try to get the org key.
                    let cur_org_key = try GetOrgKeys<OrgKeyResponse>().syncCall()
                    if let org_priv_key = cur_org_key?.privKey, !org_priv_key.isEmpty {
                        do {
                            new_org_key = try sharedOpenPGP.updatePrivateKeyPassphrase(org_priv_key, oldPassphrase: old_password, newPassphrase: new_hashed_mpwd)
                        } catch {
                            //ignore it for now.
                        }
                    }
                }
                
                var authPacket : PasswordAuth?
                if buildAuth {
                    let authModuls = try AuthModulusRequest().syncCall()
                    guard let moduls_id = authModuls?.ModulusID else {
                        throw UpdatePasswordError.invalidModulusID.error
                    }
                    guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                        throw UpdatePasswordError.invalidModulus.error
                    }
                    //generat new verifier
                    let new_decodedModulus : Data = new_encodedModulus.decodeBase64()
                    let new_lpwd_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                    guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(new_password, salt: new_lpwd_salt, modulus: new_decodedModulus) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }
                    guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                        throw UpdatePasswordError.cantGenerateVerifier.error
                    }
                    
                    authPacket = PasswordAuth(modulus_id: moduls_id,
                                              salt: new_lpwd_salt.encodeBase64(),
                                              verifer: verifier.encodeBase64())
                }
                
                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2
                
                repeat {
                    // get auto info
                    let info = try AuthInfoRequest<AuthInfoResponse>(username: _username).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
                        throw UpdatePasswordError.invalideAuthInfo.error
                    }
                    guard let encodedModulus = try modulus.getSignature() else {
                        throw UpdatePasswordError.invalideAuthInfo.error
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
                    guard let hashedPassword = PasswordUtils.getHashedPwd(hashVersion, password: login_password , username: _username, decodedSalt: decodedSalt, decodedModulus: decodedModulus) else {
                        throw UpdatePasswordError.cantHashPassword.error
                    }
                    
                    guard let srpClient = try generateSrpProofs(2048, modulus: decodedModulus, serverEphemeral: serverEphemeral, hashedPassword: hashedPassword), srpClient.isValid() == true else {
                        throw UpdatePasswordError.cantGenerateSRPClient.error
                    }
                    
                    do {
                        let update_res = try UpdatePrivateKeyRequest<ApiResponse>(clientEphemeral: srpClient.clientEphemeral.encodeBase64(),
                              clientProof:srpClient.clientProof.encodeBase64(),
                              SRPSession: session,
                              keySalt: new_mpwd_salt.encodeBase64(),
                              userlevelKeys: updated_userlevel_keys,
                              addressKeys: updated_address_keys.toKeys(),
                              tfaCode: twoFACode,
                              orgKey: new_org_key,
                              auth: authPacket).syncCall()
                        guard update_res?.code == 1000 else {
                            throw UpdatePasswordError.default.error
                        }
                        //update local keys
//                        user_info.userKeys = updated_userlevel_keys
//                        user_info.userAddresses = updated_address_keys
                        self.mailboxPassword = new_hashed_mpwd
                        self.userInfo = user_info
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
                error.upload(toFabric: "UpdateMailBoxPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
        
    }
    
    //TODO:: refactor newOrders. 
    func updateUserDomiansOrder(_ email_domains: [Address], newOrder : [String], completion: @escaping CompletionBlock) {
        let addressOrder = UpdateAddressOrder(adds: newOrder)
        addressOrder.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.userAddresses = email_domains
                    self.userInfo = userInfo
                }
            }
            completion(task, nil, nil)
        }
    }
    
    func updateUserSwipeAction(_ isLeft : Bool , action: MessageSwipeAction, completion: @escaping CompletionBlock) {
        let api = isLeft ? UpdateSwiftLeftAction(action: action) : UpdateSwiftRightAction(action: action)
        api.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.swipeLeft = isLeft ? action.rawValue : userInfo.swipeLeft
                    userInfo.swipeRight = isLeft ? userInfo.swipeRight : action.rawValue
                    self.userInfo = userInfo
                }
            }
            completion(task, nil, nil)
        }
    }
    
    func updateNotificationEmail(_ new_notification_email: String, login_password : String, twoFACode: String?, completion: @escaping CompletionBlock) {
        {//asyn
            do {
                guard let _username = self.username else {
                    throw UpdateNotificationEmailError.invalidUserName.error
                }
                
                //start check exsit srp
                var forceRetry = false
                var forceRetryVersion = 2
                
                repeat {
                    // get auto info
                    let info = try AuthInfoRequest<AuthInfoResponse>(username: _username).syncCall()
                    guard let authVersion = info?.Version, let modulus = info?.Modulus, let ephemeral = info?.ServerEphemeral, let salt = info?.Salt, let session = info?.SRPSession else {
                        throw UpdateNotificationEmailError.invalideAuthInfo.error
                    }
                    guard let encodedModulus = try modulus.getSignature() else {
                        throw UpdateNotificationEmailError.invalideAuthInfo.error
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
                    guard let hashedPassword = PasswordUtils.getHashedPwd(hashVersion, password: login_password , username: _username, decodedSalt: decodedSalt, decodedModulus: decodedModulus) else {
                        throw UpdateNotificationEmailError.cantHashPassword.error
                    }
                    
                    guard let srpClient = try generateSrpProofs(2048, modulus: decodedModulus, serverEphemeral: serverEphemeral, hashedPassword: hashedPassword), srpClient.isValid() == true else {
                        throw UpdateNotificationEmailError.cantGenerateSRPClient.error
                    }
                    
                    do {
                        let updatetNotifyEmailRes = try UpdateNotificationEmail(clientEphemeral: srpClient.clientEphemeral.encodeBase64(),
                                                                                clientProof: srpClient.clientProof.encodeBase64(),
                                                                                sRPSession: session,
                                                                                notificationEmail: new_notification_email,
                                                                                tfaCode: twoFACode).syncCall()
                        if updatetNotifyEmailRes?.code == 1000 {
                            if let userInfo = self.userInfo {
                                userInfo.notificationEmail = new_notification_email
                                self.userInfo = userInfo
                            }
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
                error.upload(toFabric: "UpdateLoginPassword")
                return { completion(nil, nil, error) } ~> .main
            }
        } ~> .async
    }
    
    func updateNotify(_ isOn: Bool, completion: @escaping CompletionBlock) {
        let notifySetting = UpdateNotify(notify: isOn ? 1 : 0)
        notifySetting.call() { task, response, hasError in
            if !hasError {
                if let userInfo = self.userInfo {
                    userInfo.notify = (isOn ? 1 : 0)
                    self.userInfo = userInfo
                }
            }
            completion(task, nil, nil)
        }
    }
    
    func updateSignature(_ signature: String, completion: UserInfoBlock?) {
        sharedAPIService.settingUpdateSignature(signature, completion: completionForUserInfo(completion))
    }
    
    // MARK: - Private methods
    
    func cleanUpIfFirstRun() {
        let firstRunKey = "FirstRunKey"
        if SharedCacheBase.getDefault().object(forKey: firstRunKey) == nil {
            clearAll()
            SharedCacheBase.getDefault().set(Date(), forKey: firstRunKey)
            SharedCacheBase.getDefault().synchronize()
        }
    }
    
    func clearAll() {
        isSignedIn = false
        
        isRememberUser = false
        password = nil
        username = nil
        
        isRememberMailboxPassword = false
        mailboxPassword = nil
        userInfo = nil
        twoFactorStatus = 0
        passwordMode = 2
        
        //sharedOpenPGP.cleanAddresses()
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
        if !self.isRememberUser {
            username = nil
            password = nil
            twoFactorStatus = 0
            passwordMode = 2
        }
        
        if !isRememberMailboxPassword {
            mailboxPassword = nil
        }
    }
}

