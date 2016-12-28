//
//  SignupViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/29/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


public class SignupViewModelImpl : SignupViewModel {
    private var userName : String = ""
    private var token : String = ""
    private var isExpired : Bool = true
    private var newKey : PMNOpenPgpKey?
    private var domain : String = ""
    private var destination : String = ""
    private var recoverEmail : String = ""
    private var news : Bool = true
    private var plaintext_password : String = ""
    private var agreePolicy : Bool = false
    private var displayName : String = ""
    
    private var lastSendTime : NSDate?
    
    private var keysalt : NSData?
    private var bit : Int32 = 2048
    
    private var delegate : SignupViewModelDelegate?
    private var verifyType : VerifyCodeType = .email
    
    private var direct : [String] = []
    
    override func getDirect() -> [String] {
        return direct
    }
    
    override init() {
        super.init()
        //register observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignupViewModelImpl.notifyReceiveURLSchema(_:)), name: NotificationDefined.CustomizeURLSchema, object:nil)
    }
    deinit {
        //unregister observer
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDefined.CustomizeURLSchema, object:nil)
    }
    
    internal func notifyReceiveURLSchema (notify: NSNotification) {
        if let verifyCode = notify.userInfo?["verifyCode"] as? String {
            delegate?.verificationCodeChanged(self, code: verifyCode)
        }
    }
    
    override func setDelegate(delegate: SignupViewModelDelegate?) {
        self.delegate = delegate
    }
    
    override func checkUserName(username: String, complete: CheckUserNameBlock!) {
        // need valide user name format
        let api = CheckUserExistRequest<CheckUserExistResponse>(userName: username)
        api.call { (task, response, hasError) -> Void in
            complete(response?.isAvailable ?? false, response?.error)
        }
    }
    
    override func getCurrentBit() -> Int32 {
        return self.bit
    }
    
    override func setBit(bit: Int32) {
        self.bit = bit
    }
    
    override func setRecaptchaToken(token: String, isExpired: Bool) {
        self.token = token
        self.isExpired = isExpired
        self.verifyType = .recaptcha
    }
    
    override func setPickedUserName(username: String, domain:String) {
        self.userName = username
        self.domain = domain
    }
    
    override func isTokenOk() -> Bool {
        return !isExpired
    }
    
    override func setEmailVerifyCode(code: String) {
        self.token = code
        self.isExpired = false
        self.verifyType = .email
    }
    
    override func setPhoneVerifyCode (code: String) {
        self.token = code
        self.isExpired = false
        self.verifyType = .sms
    }
    
    override func generateKey(complete: GenerateKey) {
        {
            do {
                //generate key salt
                let new_mpwd_salt : NSData = PMNOpenPgp.randomBits(128) //mailbox pwd need 128 bits
                //generate key hashed password.
                let new_hashed_mpwd = PasswordUtils.getMailboxPassword(self.plaintext_password, salt: new_mpwd_salt)
                self.keysalt = new_mpwd_salt
                //generate new key
                self.newKey = try sharedOpenPGP.generateKey(new_hashed_mpwd, userName: self.userName, domain: self.domain, bits: self.bit);
                
                {
                    // do some async stuff
                    if self.newKey == nil {
                        complete(true, "Key generation failed please try again", nil)
                    } else {
                        complete(false, nil, nil);
                    }
                } ~> .Main
            }
            catch let ex as NSError {
                { complete(false, "Key generation failed please try again", ex) } ~> .Main
            }
        } ~> .Async
    }
    
    override func createNewUser(complete: CreateUserBlock) {
        //validation here
        if let key = self.newKey {
            {
                do {
                    let authModuls = try AuthModulusRequest<AuthModulusResponse>().syncCall()
                    guard let moduls_id = authModuls?.ModulusID else {
                        throw SignUpCreateUserError.InvalidModulsID.toError()
                    }
                    guard let new_moduls = authModuls?.Modulus, let new_encodedModulus = try new_moduls.getSignature() else {
                        throw SignUpCreateUserError.InvalidModuls.toError()
                    }
                    //generat new verifier
                    let new_decodedModulus : NSData = new_encodedModulus.decodeBase64()
                    let new_salt : NSData = PMNOpenPgp.randomBits(80) //for the login password needs to set 80 bits
                    guard let new_hashed_password = PasswordUtils.hashPasswordVersion4(self.plaintext_password, salt: new_salt, modulus: new_decodedModulus) else {
                        throw SignUpCreateUserError.CantHashPassword.toError()
                    }
                    guard let verifier = try generateVerifier(2048, modulus: new_decodedModulus, hashedPassword: new_hashed_password) else {
                        throw SignUpCreateUserError.CantGenerateVerifier.toError()
                    }
                    
                    let api = CreateNewUserRequest<ApiResponse>(token: self.token,
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
                            
                            //need setup address
                            
                            //need setup keys
                            
                            
                            
                            //need pass twoFACode
//                            sharedUserDataService.signIn(self.userName, password: self.login, twoFACode: nil,
//                                ask2fa: {
//                                    //2fa will show error
//                                    complete(false, true, "2fa Authentication failed please try to login again", nil)
//                                },
//                                onError: { (error) in
//                                    complete(false, true, "Authentication failed please try to login again", error);
//                                },
//                                onSuccess: { (mailboxpwd) in
//                                    do {
//                                        if sharedUserDataService.isMailboxPasswordValid(self.mailbox, privateKey: AuthCredential.getPrivateKey()) {
//                                            try AuthCredential.setupToken(self.mailbox, isRememberMailbox: true)
//                                            sharedLabelsDataService.fetchLabels()
//                                            sharedUserDataService.fetchUserInfo() { info, _, error in
//                                                 if error != nil {
//                                                    complete(false, true, "Fetch user info failed", error)
//                                                } else if info != nil {
//                                                    sharedUserDataService.isNewUser = true
//                                                    sharedUserDataService.setMailboxPassword(self.mailbox, keysalt: nil, isRemembered: true)
//                                                    complete(true, true, "", nil)
//                                                } else {
//                                                    complete(false, true, "Unknown Error", nil)
//                                                }
//                                            }
//                                        } else {
//                                            complete(false, true, "Decrypt token failed please try again", nil);
//                                        }
//                                    } catch let ex as NSError {
//                                        PMLog.D(ex)
//                                        complete(false, true, "Decrypt token failed please try again", nil);
//                                    }
//                            })
                        } else {
                            if response?.error?.code == 7002 {
                                complete(false, true, "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", response!.error);
                            } else {
                                complete(false, false, "Create User failed please try again", response!.error);
                            }
                        }
                    })
                } catch {
                    //complete(false, true, "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", response!.error);
                }
                

            } ~> .Async
            
        } else {
            complete(false, false, "Key invalid please go back try again", nil);
        }
    }
    
    override func sendVerifyCode(type: VerifyCodeType, complete: SendVerificationCodeBlock!) {
        let api = VerificationCodeRequest(userName: self.userName, destination: destination, type: type)
        api.call { (task, response, hasError) -> Void in
            if !hasError {
                self.lastSendTime = NSDate()
            }
            complete(!hasError, response?.error)
        }
    }
    
    override func setRecovery(receiveNews: Bool, email: String, displayName : String) {
        self.recoverEmail = email
        self.news = receiveNews
        self.displayName = displayName
        
        if !self.displayName.isEmpty {
            sharedUserDataService.updateDisplayName(displayName) { _, _, error in
                //                if error != nil {
                //                    //complete(false, error)
                //                } else {
                //                    //complete(true, nil)
                //                }
            }
        }
        
        if !self.recoverEmail.isEmpty {
            sharedUserDataService.updateNotificationEmail(recoverEmail, login_password: sharedUserDataService.password ?? "", twoFACode: nil) { _, _, error in
                //                if error != nil {
                //                    //complete(false, error)
                //                } else {
                //                    //complete(true, nil)
                //                }
            }
        }
        
        if self.news {
            let newsApi = UpdateNewsRequest(news: self.news)
            newsApi.call { (task, response, hasError) -> Void in
                
            }
        }
    }
    
    override func fetchDirect(res : (directs:[String]) -> Void) {
        if direct.count <= 0 {
            let api = DirectRequest<DirectResponse>()
            api.call { (task, response, hasError) -> Void in
                if hasError {
                    res(directs: [])
                } else {
                    self.direct = response?.signupFunctions ?? []
                    res(directs: self.direct)
                }
            }
        } else {
            res(directs: self.direct)
        }
    }
    
    override func setCodeEmail(email: String) {
        self.destination = email
        self.recoverEmail = email
        self.news = true
    }
    
    override func setCodePhone(phone: String) {
        self.destination = phone
    }
    
    override func setSinglePassword(password: String) {
        self.plaintext_password = password
    }
    
    override func setAgreePolicy(isAgree: Bool) {
        self.agreePolicy = isAgree;
    }
    
    private var count : Int = 10;
    override func getTimerSet() -> Int {
        if let lastTime = lastSendTime {
            let time = NSDate().timeIntervalSinceDate(lastTime)
            let newCount = 120 - Int(time);
            if newCount <= 0 {
                lastSendTime = nil
            }
            return newCount > 0 ? newCount : 0;
        } else {
            return 0
        }
    }
}
