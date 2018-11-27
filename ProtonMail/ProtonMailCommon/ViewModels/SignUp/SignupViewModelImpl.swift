//
//  SignupViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/29/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


final class SignupViewModelImpl : SignupViewModel {
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
    
    fileprivate var direct : [String] = []
    
    override func getDirect() -> [String] {
        return direct
    }
    
    override init() {
        super.init()
        //register observer
        NotificationCenter.default.addObserver(self, selector: #selector(SignupViewModelImpl.notifyReceiveURLSchema(_:)), name: NSNotification.Name(rawValue: NotificationDefined.CustomizeURLSchema), object:nil)
    }
    deinit {
        //unregister observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDefined.CustomizeURLSchema), object:nil)
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
        // need valide user name format
        let api = CheckUserExist(userName: username)
        api.call { (task, response, hasError) -> Void in
            complete(response?.isAvailable ?? false, response?.error)
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
    
    override func createNewUser(_ complete: @escaping CreateUserBlock) {
        //validation here
        if let key = self.newPrivateKey {
            {
                do {
                    let authModuls = try AuthModulusRequest().syncCall()
                    guard let moduls_id = authModuls?.ModulusID else {
                        throw SignUpCreateUserError.invalidModulsID.error
                    }
                    guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                        throw SignUpCreateUserError.invalidModuls.error
                    }
                    //generat new verifier
                    let new_decodedModulus : Data = new_encodedModulus.decodeBase64()
                    let new_salt : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                    guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(self.plaintext_password, salt: new_salt, modulus: new_decodedModulus) else {
                        throw SignUpCreateUserError.cantHashPassword.error
                    }
                    guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                        throw SignUpCreateUserError.cantGenerateVerifier.error
                    }
                    
                    let api = CreateNewUser(token: self.token,
                                            type: self.verifyType.toString, username: self.userName,
                                            email: self.recoverEmail, news: self.news,
                                            modulusID: moduls_id,
                                            salt: new_salt.encodeBase64(),
                                            verifer: verifier.encodeBase64())
                    api.call({ (task, response, hasError) -> Void in
                        if !hasError {
                            //need clean the cache without ui flow change then signin with a fresh user
                            sharedUserDataService.signOutAfterSignUp()
                            userCachedStatus.signOut()
                            sharedMessageDataService.launchCleanUpIfNeeded()
                            
                            //login first
                            sharedUserDataService.signIn(self.userName, password: self.plaintext_password, twoFACode: nil,
                                ask2fa: {
                                    //2fa will show error
                                    complete(false, true, LocalString._signup_2fa_auth_failed, nil)
                                },
                                onError: { (error) in
                                    complete(false, true, LocalString._authentication_failed_pls_try_again, error);
                                },
                                onSuccess: { (mailboxpwd) in
                                    {
                                        do {
                                            try AuthCredential.setupToken(self.keypwd_with_keysalt, isRememberMailbox: true)
                                            
                                            //need setup address
                                            let setupAddrApi = try SetupAddressRequest(domain_name: self.domain).syncCall()
                                            
                                            //need setup keys
                                            let authModuls_for_key = try AuthModulusRequest().syncCall()
                                            guard let moduls_id_for_key = authModuls_for_key?.ModulusID else {
                                                throw SignUpCreateUserError.invalidModulsID.error
                                            }
                                            guard let new_moduls_for_key = authModuls_for_key?.Modulus, let new_encodedModulus_for_key = try new_moduls_for_key.getSignature() else {
                                                throw SignUpCreateUserError.invalidModuls.error
                                            }
                                            //generat new verifier
                                            let new_decodedModulus_for_key : Data = new_encodedModulus_for_key.decodeBase64()
                                            let new_salt_for_key : Data = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                                            guard let new_hashed_password_for_key = PasswordUtils.hashPasswordVersion4(self.plaintext_password, salt: new_salt_for_key, modulus: new_decodedModulus_for_key) else {
                                                throw SignUpCreateUserError.cantHashPassword.error
                                            }
                                            guard let verifier_for_key = try generateVerifier(2048, modulus: new_decodedModulus_for_key, hashedPassword: new_hashed_password_for_key) else {
                                                throw SignUpCreateUserError.cantGenerateVerifier.error
                                            }
                                            
                                            let addr_id = setupAddrApi?.addresses.first?.address_id
                                            let pwd_auth = PasswordAuth(modulus_id: moduls_id_for_key,salt: new_salt_for_key.encodeBase64(), verifer: verifier_for_key.encodeBase64())
                                            
                                            let setupKeyApi = try SetupKeyRequest<ApiResponse>(address_id: addr_id,
                                                                                               private_key: key,
                                                                                               keysalt: self.keysalt!.encodeBase64(),
                                                                                               auth: pwd_auth).syncCall()
                                            if setupKeyApi?.error != nil {
                                                PMLog.D("signup seupt key error")
                                            }
                                            
                                            //setup swipe function
                                            let _ = try UpdateSwiftLeftAction(action: MessageSwipeAction.archive).syncCall()
                                            let _ = try UpdateSwiftRightAction(action: MessageSwipeAction.trash).syncCall()

                                            sharedLabelsDataService.fetchLabels()
                                            ServicePlanDataService.shared.updateCurrentSubscription()
                                            sharedUserDataService.fetchUserInfo().done(on: .main) { info in
                                                if info != nil {
                                                    sharedUserDataService.isNewUser = true
                                                    sharedUserDataService.setMailboxPassword(self.keypwd_with_keysalt, keysalt: nil)
                                                    //alway signle password mode when signup
                                                    sharedUserDataService.passwordMode = 1
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
                            })
                        } else {
                            if response?.error?.code == 7002 {
                                complete(false, true, LocalString._account_creation_has_been_disabled_pls_go_to_https, response!.error);
                            } else {
                                complete(false, false, LocalString._create_user_failed_please_try_again, response!.error);
                            }
                        }
                    })
                } catch {
                    complete(false, false, LocalString._create_user_failed_please_try_again, nil);
                }
                
            } ~> .async
            
        } else {
            complete(false, false, LocalString._key_invalid_please_go_back_try_again, nil);
        }
    }
    
    override func sendVerifyCode(_ type: VerifyCodeType, complete: SendVerificationCodeBlock!) {
        let api = VerificationCodeRequest(userName: self.userName, destination: destination, type: type)
        api.call { (task, response, hasError) -> Void in
            if !hasError {
                self.lastSendTime = Date()
            }
            complete(!hasError, response?.error)
        }
    }
    
    override func setRecovery(_ receiveNews: Bool, email: String, displayName : String) {
        self.recoverEmail = email
        self.news = receiveNews
        self.displayName = displayName
        
        if !self.displayName.isEmpty {
            sharedUserDataService.updateDisplayName(displayName) { _, _, error in

            }
        }
        
        if !self.recoverEmail.isEmpty {
            sharedUserDataService.updateNotificationEmail(recoverEmail, login_password: self.plaintext_password, twoFACode: nil) { _, _, error in

            }
        }
        
        if self.news {
            let newsApi = UpdateNewsRequest(news: self.news)
            newsApi.call { (task, response, hasError) -> Void in
                
            }
        }
    }
    
    override func fetchDirect(_ res : @escaping (_ directs:[String]) -> Void) {
        if direct.count <= 0 {
            let api = DirectRequest()
            api.call { (task, response, hasError) -> Void in
                if hasError {
                    res([])
                } else {
                    self.direct = response?.signupFunctions ?? []
                    res(self.direct)
                }
            }
        } else {
            res(self.direct)
        }
    }
    
    override func setCodeEmail(_ email: String) {
        self.destination = email
        self.recoverEmail = email
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
        api.call({ (task, response, hasError) -> Void in
            if hasError {
                complete(defaultDomains)
            } else if let domains = response?.domains {
                complete(domains)
            } else {
                complete(defaultDomains)
            }
        })
    }
}
