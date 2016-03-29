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
    private var codeEmail : String = ""
    private var recoverEmail : String = ""
    private var news : Bool = true
    private var login : String = ""
    private var mailbox : String = "";
    private var agreePolicy : Bool = false
    private var displayName : String = ""
    
    private var lastSendTime : NSDate?
    
    private var bit : Int32 = 2048
    
    private var delegate : SignupViewModelDelegate?
    private var verifyType : VerifyCodeType = .email
    
    override init() {
        super.init()
        //register observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notifyReceiveURLSchema:", name: NotificationDefined.CustomizeURLSchema, object:nil)
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
    
    override func setVerifyCode(code: String) {
        self.token = code
        self.isExpired = false
        self.verifyType = .email
    }
    
    override func generateKey(complete: GenerateKey) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            var error: NSError?
            self.newKey = sharedOpenPGP.generateKey(self.mailbox, userName: self.userName, domain: self.domain, bits: self.bit, error: &error)
            NSOperationQueue.mainQueue().addOperationWithBlock {
                // do some async stuff
                if error == nil {
                    complete(true, nil, nil)
                } else {
                    complete(false, "Key generation failed please try again", error);
                }
            }
        }
    }
    
    override func createNewUser(complete: CreateUserBlock) {
        //validation here
        var error: NSError?
        if let key = self.newKey { // sharedOpenPGP.generateKey(self.mailbox, userName: self.userName, domain: self.domain, bits: 4096, error: &error) {
            let api = CreateNewUserRequest<ApiResponse>(token: self.token, type: self.verifyType.toString, username: self.userName, password: self.login, email: self.recoverEmail, domain: self.domain, news: self.news, publicKey: key.publicKey, privateKey: key.privateKey)
            api.call({ (task, response, hasError) -> Void in
                if !hasError {
                    sharedUserDataService.signIn(self.userName, password: self.login, isRemembered: true) { _, error in
                        if let error = error {
                            complete(false, true, "Authentication failed please try to login again", nil);
                        } else {
                            if sharedUserDataService.isMailboxPasswordValid(self.mailbox, privateKey: AuthCredential.getPrivateKey()) {
                                AuthCredential.setupToken(self.mailbox, isRememberMailbox: true)
                                sharedLabelsDataService.fetchLabels()
                                sharedUserDataService.fetchUserInfo() { info, error in
                                    if error != nil {
                                        complete(false, true, "Fetch user info failed", error)
                                    } else if info != nil {
                                        sharedUserDataService.isNewUser = true
                                        sharedUserDataService.setMailboxPassword(self.mailbox, isRemembered: true)
                                        complete(true, true, "", nil)
                                    } else {
                                        complete(false, true, "Unknown Error", nil)
                                    }
                                }
                            } else {
                                complete(false, true, "Decrypt token failed please try again", nil);
                            }
                        }
                    }
                } else {
                    if response?.error?.code == 7002 {
                        complete(false, true, "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", response!.error);
                    } else {
                        complete(false, false, "Create User failed please try again", response!.error);
                    }
                }
            })
        } else {
            complete(false, false, "Key invalid please go back try again", nil);
        }
    }
    
    override func sendVerifyCode(complete: SendVerificationCodeBlock!) {
        let api = VerificationCodeRequest(userName: self.userName, emailAddress: codeEmail, type: .email)
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
            sharedUserDataService.updateDisplayName(displayName) { _, error in
                if let error = error {
                    //complete(false, error)
                } else {
                    //complete(true, nil)
                }
            }
        }
        
        if !self.recoverEmail.isEmpty {
            sharedUserDataService.updateNotificationEmail(recoverEmail) { _, _, error in
                if let error = error {
                    //complete(false, error)
                } else {
                    //complete(true, nil)
                }
            }
        }
        
        if self.news {
            let newsApi = UpdateNewsRequest(news: self.news)
            newsApi.call { (task, response, hasError) -> Void in
                
            }
        }
    }
    
    override func setCodeEmail(email: String) {
        self.codeEmail = email
        self.recoverEmail = email
        self.news = true
    }
    
    override func setPasswords(loginPwd: String, mailboxPwd: String) {
        self.login = loginPwd
        self.mailbox = mailboxPwd
    }
    
    override func setAgreePolicy(isAgree: Bool) {
        self.agreePolicy = isAgree;
    }
    
    private var count : Int = 10;
    override func getTimerSet() -> Int {
        if let lastTime = lastSendTime {
            let currentDate = NSDate()
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