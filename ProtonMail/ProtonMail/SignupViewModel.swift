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
    
    func setPickedUserName ( username : String ) {
        fatalError("This method must be overridden")
    }
    
    func isTokenOk() -> Bool {
        fatalError("This method must be overridden")
    }
    
}


public class SignupViewModelImpl : SignupViewModel {
    
    private var userName : String = ""
    private var token : String = ""
    private var isExpired : Bool = true

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
    
    override func setPickedUserName(username: String) {
        self.userName = username
    }
    
    override func isTokenOk() -> Bool {
        return !isExpired
    }
}