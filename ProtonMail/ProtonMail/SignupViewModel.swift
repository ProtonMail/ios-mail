//
//  SignupViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/18/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


public class SignupViewModel {
    
    func checkUserName(username: String, complete: CheckUserNameBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    func setRecaptchaToken (token : String, isExpired : Bool ) {
        fatalError("This method must be overridden")
    }
    
    func setPickedUserName (username: String, domain:String) {
        fatalError("This method must be overridden")
    }
    
    func isTokenOk() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func createNewUser(complete : CreateUserBlock) {
        fatalError("This method must be overridden")
    }
    
    func setRecovery(receiveNews:Bool, email : String) {
        fatalError("This method must be overridden")
    }
    
    func setPasswords(loginPwd:String, mailboxPwd:String) {
        fatalError("This method must be overridden")
    }
}


public class SignupViewModelImpl : SignupViewModel {
    private var userName : String = ""
    private var token : String = ""
    private var isExpired : Bool = true
    private var newKey : PMNOpenPgpKey?
    private var domain : String = ""
    private var email : String = ""
    private var news : Bool = false
    private var login : String = ""
    private var mailbox : String = "";

    override func checkUserName(username: String, complete: CheckUserNameBlock!) {
        let api = CheckUserExistRequest<CheckUserExistResponse>(userName: username)
        api.call { (task, response, hasError) -> Void in
            complete(response?.isAvailable ?? false, response?.error)
        }
    }
    
    override func setRecaptchaToken(token: String, isExpired: Bool) {
        self.token = token
        self.isExpired = isExpired
    }
    
    override func setPickedUserName(username: String, domain:String) {
        self.userName = username
        self.domain = domain
    }
    
    override func isTokenOk() -> Bool {
        return !isExpired
    }
    
    override func createNewUser(complete: CreateUserBlock) {
        //validation here
        var error: NSError?
        if let key = sharedOpenPGP.generateKey(self.mailbox, userName: self.userName, domain: self.domain, error: &error) {
            let api = CreateNewUserRequest<ApiResponse>(token: self.token, username: self.userName, password: self.login, email: self.email, domain: self.domain, news: self.news, publicKey: key.publicKey, privateKey: key.privateKey)
            api.call({ (task, response, hasError) -> Void in
                if !hasError {
                    sharedUserDataService.signIn(self.userName, password: self.login, isRemembered: true) { _, error in
                        if let error = error {
                            complete(false, true, "Authentication failed please try to login again", nil);
                        } else {
                            sharedUserDataService.isSignedIn = true
                            if sharedUserDataService.isMailboxPasswordValid(self.mailbox, privateKey: AuthCredential.getPrivateKey()) {
                                if sharedUserDataService.isSet {
                                    sharedUserDataService.setMailboxPassword(self.mailbox, isRemembered: true)
                                    (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
                                } else {
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
                                }
                            } else {
                                complete(false, true, "Decrypt token failed please try again", nil);
                            }
                        }
                    }
                } else {
                    complete(false, true, "Create User failed please try again", response!.error);
                }
            })
        } else {
            complete(false, false, "Key generation failed please try again", nil);
        }
    }
    
    override func setRecovery(receiveNews: Bool, email: String) {
        self.email = email
        self.news = receiveNews
    }
    
    override func setPasswords(loginPwd: String, mailboxPwd: String) {
        self.login = loginPwd
        self.mailbox = mailboxPwd
    }
}