//
//  SignupViewModelImpl.swift
//  ProtonMail - Created on 3/29/16.
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
import Crypto
import PMChallenge
import PMCommon
import PromiseKit
import AwaitKit

final class AccountSignupViewModelImpl : SignupViewModelImpl {
    override func isAccountManager() -> Bool {
        return true
    }
}

class SignupViewModelImpl : SignupViewModel {
    fileprivate var userName : String = ""
    fileprivate var token : String = ""
    fileprivate var isExpired : Bool = true
    fileprivate var newPrivateKey : String?
    fileprivate var domain : String = ""
    fileprivate var destination : String = ""
    fileprivate var recoverEmail : String = ""
    fileprivate var news : Bool = true
    fileprivate var plaintext_password : String = ""
    fileprivate var agreePolicy : Bool = false
    fileprivate var displayName : String = ""
    
    fileprivate var lastSendTime : Date?
    
    fileprivate var keysalt : Data?
    fileprivate var keypwd_with_keysalt : String = ""
    fileprivate var bit : Int = 2048
    
    fileprivate var delegate : SignupViewModelDelegate?
    fileprivate var verifyType : VerifyCodeType = .email
    fileprivate var challenge = PMChallenge()
    
    fileprivate var direct : [String] = []
    
    let deviceCheckToken: String
    let apiService = PMAPIService.shared
    
    let usersManager: UsersManager
    
    weak var userManager: UserManager?
    let signinManager: SignInManager
    
    override func getDirect() -> [String] {
        return direct
    }
    
    init(token: String, usersManager: UsersManager, signinManager: SignInManager ) {
        self.deviceCheckToken = token
        self.usersManager = usersManager
        self.signinManager = signinManager
        super.init()
        //register observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SignupViewModelImpl.notifyReceiveURLSchema(_:)),
                                               name: .customUrlSchema,
                                               object:nil)
    }
    deinit {
        //unregister observer
        NotificationCenter.default.removeObserver(self, name: .customUrlSchema, object:nil)
    }
    
    @objc internal func notifyReceiveURLSchema (_ notify: Notification) {
        if let verifyCode = notify.userInfo?["verifyCode"] as? String {
            delegate?.verificationCodeChanged(self, code: verifyCode)
        }
    }
    
    override func setDelegate(_ delegate: SignupViewModelDelegate?) {
        self.delegate = delegate
    }
    
    override func checkUserName(_ username: String, complete: CheckUserNameBlock!) {
        
        self.challenge.appendCheckedUsername(username)
        
        // need valide user name format
        let api = CheckUserExist(userName: username)
        self.apiService.exec(route: api) { (task, response: CheckUserExistResponse) in
            if let error = response.error {
                complete(.rejected(error))
            } else if let status = response.availabilityStatus {
                complete(.fulfilled(status))
            } else {
                complete(.rejected(NSError.init(domain: "", code: 0, localizedDescription: "Failed to determine status")))
            }
        }
    }
    
    override func getCurrentBit() -> Int {
        return self.bit
    }
    
    override func setBit(_ bit: Int) {
        self.bit = bit
    }
    
    override func setRecaptchaToken(_ token: String, isExpired: Bool) {
        self.token = token
        self.isExpired = isExpired
        self.verifyType = .recaptcha
    }
    
    override func setPickedUserName(_ username: String, domain:String) {
        self.userName = username
        self.domain = domain
    }
    
    override func isTokenOk() -> Bool {
        return !isExpired
    }
    
    override func setEmailVerifyCode(_ code: String) {
        self.token = code
        self.isExpired = false
        self.verifyType = .email
    }
    
    override func setPhoneVerifyCode (_ code: String) {
        self.token = code
        self.isExpired = false
        self.verifyType = .sms
    }
    
    override func generateKey(_ complete: @escaping GenerateKey) {
        {
            do {
                
                //generate key salt
                let new_mpwd_salt : Data = PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                //generate key hashed password.
                let new_hashed_mpwd = PasswordUtils.getMailboxPassword(self.plaintext_password, salt: new_mpwd_salt)
                self.keysalt = new_mpwd_salt
                self.keypwd_with_keysalt = new_hashed_mpwd
                //generate new key
                
//                self.newPrivateKey = try sharedOpenPGP.generateKey(self.userName,
//                                                                   domain: self.domain,
//                                                                   passphrase: new_hashed_mpwd,
//                                                                   keyType: "rsa", bits: self.bit);
                let pgp = PMNOpenPgp.createInstance()!
                let newK = try pgp.generateKey(new_hashed_mpwd,
                                               userName: self.userName,
                                               domain: self.domain,
                                               bits: Int32(self.bit))
                self.newPrivateKey = newK?.privateKey;
                
                {
                    
                    // do some async stuff
                    if self.newPrivateKey == nil {
                        complete(true, LocalString._key_generation_failed_please_try_again, nil)
                    } else {
                        complete(false, nil, nil);
                    }
                } ~> .main
            }
            catch let ex as NSError {
                { complete(false, LocalString._key_generation_failed_please_try_again, ex) } ~> .main
            }
        } ~> .async
    }
    
    
    /// Create new user. this is will be triggered by the continue button after the human verification
    /// - Parameter complete: complete delegation
    override func createNewUser(_ complete: @escaping CreateUserBlock) {
        //validation here
        
        let keyManager: KeyManager = KeyManager(api: self.apiService)
        if let key = self.newPrivateKey {
            {
                do {
                    let passwordAuth = try keyManager.generatPasswordAuth(password: self.plaintext_password)
                    let challenge = self.challenge.export().toDictionary()
                    let api = CreateNewUser(token: self.token,
                                            type: self.verifyType.toString, username: self.userName,
                                            email: self.recoverEmail,
                                            passwordAuth: passwordAuth,
                                            deviceToken: self.deviceCheckToken,
                                            challenge: challenge)
                    self.apiService.exec(route: api) { (task, response) -> Void in
                        if let error = response.error {
                            if error.code == 7002 {
                                complete(false, true, LocalString._account_creation_has_been_disabled_pls_go_to_https, response.error);
                            } else {
                                complete(false, false, LocalString._create_user_failed_please_try_again, response.error);
                            }
                        } else {
                            self.signinManager.signUpSignIn(username: self.userName, password: self.plaintext_password, onError: { (error) in
                                complete(false, true, LocalString._authentication_failed_pls_try_again, error);
                            }) { (pwd, auth, userInfo) in
                                {
                                    do {
                                        // update the auth object, setup the key password
                                        auth?.udpate(password: self.keypwd_with_keysalt)
                                        
                                        guard !key.fingerprint.isEmpty else {
                                            //TODO:: change to a key error
                                            throw SignUpCreateUserError.cantHashPassword.error
                                        }
                                        
                                        try keyManager.initAddressKey(password: self.plaintext_password,
                                                                      keySalt: self.keysalt!.encodeBase64(),
                                                                      keyPassword: self.keypwd_with_keysalt,
                                                                      privateKey: key,
                                                                      domain: self.domain, authCredential: auth)
                                        
//                                        let setupKeyApi = try await(self.apiService.run(route: setupKeyReq))
//                                        if setupKeyApi.error != nil {
//                                            PMLog.D("signup seupt key error")
//                                        }
                                        
                                        auth?.update(salt: self.keysalt!.encodeBase64(), privateKey: self.newPrivateKey)
                                        //setup swipe function, will use default auth credential
                                        let _ = try await(self.apiService.run(route: UpdateSwiftLeftAction(action: MessageSwipeAction.archive,
                                                                                                           authCredential: auth)))
                                        let _ = try await(self.apiService.run(route: UpdateSwiftRightAction(action: MessageSwipeAction.trash,
                                                                                                            authCredential: auth)))
                                        //sharedLabelsDataService.fetchLabels()
                                        //ServicePlanDataService.shared.updateCurrentSubscription()
                                        //TODO:: this part looks strange.
                                        UserDataService(api: PMAPIService.unauthorized).fetchUserInfo(auth: auth).done(on: .main) { info in
                                            if info != nil {
                                                sharedUserDataService.isNewUser = true
                                                //sharedUserDataService.setMailboxPassword(self.keypwd_with_keysalt, keysalt: nil)
                                                //alway signle password mode when signup
                                                sharedUserDataService.passwordMode = 1

                                                self.usersManager.add(auth: auth!, user: info!)
                                                let user = self.usersManager.getUser(bySessionID: auth!.sessionID)!
                                                self.userManager = user
                                                let labelService = user.labelService
                                                labelService.fetchLabels()
                                                self.usersManager.loggedIn()
                                                self.usersManager.active(uid: auth!.sessionID)
                                                complete(true, true, "", nil)
                                            } else {
                                                complete(false, true, LocalString._unknown_error, nil)
                                            }
                                        }.catch(on: .main) { error in
                                            complete(false, true, LocalString._fetch_user_info_failed, error)
                                        }
                                    } catch let ex as NSError {
                                        PMLog.D(any: ex)
                                        complete(false, true, ex.localizedDescription, nil);
                                    }
                                } ~> .async
                            }
                        }
                    }
                } catch {
                    complete(false, false, LocalString._create_user_failed_please_try_again, nil);
                }

            } ~> .async

        } else {
            complete(false, false, LocalString._key_invalid_please_go_back_try_again, nil);
        }
    }
    
    override func sendVerifyCode(_ type: VerifyCodeType, complete: SendVerificationCodeBlock!) {
        
        self.challenge.requestVerify()
        
        let api = VerificationCodeRequest(userName: self.userName, destination: destination, type: type)
        self.apiService.exec(route: api) { (task, response) in
            if response.error == nil {
                self.lastSendTime = Date()
            }
            complete(response.error)
        }
    }
    
    override func setRecovery(_ receiveNews: Bool, email: String, displayName : String) {
        self.recoverEmail = email
        self.news = receiveNews
        self.displayName = displayName
        
        guard let user = self.userManager else {
            return
        }
        
        if !self.displayName.isEmpty {
            if let addr = user.addresses.defaultAddress() {
                user.userService.updateAddress(auth: user.auth, user: user.userInfo,
                                               addressId: addr.address_id, displayName: displayName,
                                               signature: addr.signature, completion: { (_, _, error) in
                    
                })
            } else {
                user.userService.updateDisplayName(auth: user.auth,
                                                   user: user.userInfo,
                                                   displayName: displayName) { _, _, error in
                    
                }
            }
        }
        
        if !self.recoverEmail.isEmpty {
            
            user.userService.updateNotificationEmail(auth: user.auth, user: user.userInfo,
                                                     new_notification_email: recoverEmail, login_password: self.plaintext_password,
                                                     twoFACode: nil) { _, _, error in

            }
        }
        
        let api = UpdateNewsRequest(news: self.news, auth: user.auth)
        self.apiService.exec(route: api) { (_, _) in
            //Ignroe the response event this failed it houldn't block the process
        }
    }
    
    override func fetchDirect(_ res : @escaping (_ directs:[String]) -> Void) {
        if direct.count <= 0 {
            let api = DirectRequest()
            self.apiService.exec(route: api) { (task, response: DirectResponse) in
                if let error = response.error {
                    res([])
                } else {
                    self.direct = response.signupFunctions ?? []
                    res(self.direct)
                }
            }
        } else {
            res(self.direct)
        }
    }
    
    override func setCodeEmail(_ email: String) {
        self.destination = email
        //self.recoverEmail = email
        self.news = true
    }
    
    override func setCodePhone(_ phone: String) {
        self.destination = phone
    }
    
    override func setSinglePassword(_ password: String) {
        self.plaintext_password = password
    }
    
    override func setAgreePolicy(_ isAgree: Bool) {
        self.agreePolicy = isAgree;
    }
    
    fileprivate var count : Int = 10;
    override func getTimerSet() -> Int {
        if let lastTime = lastSendTime {
            let time = Date().timeIntervalSince(lastTime)
            let newCount = 120 - Int(time);
            if newCount <= 0 {
                lastSendTime = nil
            }
            return newCount > 0 ? newCount : 0;
        } else {
            return 0
        }
    }
    
    override func getDomains(_ complete : @escaping AvailableDomainsComplete) -> Void {
        let defaultDomains = ["protonmail.com", "protonmail.ch"]
        let api = GetAvailableDomainsRequest()
        self.apiService.exec(route: api) { (task, response: AvailableDomainsResponse) in
            if let domains = response.domains {
                complete(domains)
            } else {
                complete(defaultDomains)
            }
        }
    }
    
    override func observeTextField(textField: UITextField, type: PMChallenge.TextFieldType) {
        try! self.challenge.observeTextField(textField, type: type)
    }
    
    override func requestHumanVerification() {
        self.challenge.requestVerify()
    }
    
    override func humanVerificationFinish() {
        try? self.challenge.verificationFinish()
    }
    
    override func challengeExport() -> PMChallenge.Challenge {
        return self.challenge.export()
    }
}
