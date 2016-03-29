//
//  SignupViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/18/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


protocol SignupViewModelDelegate{
    func verificationCodeChanged(viewModel : SignupViewModel, code : String!)
}

public class SignupViewModel : NSObject {
    func setDelegate (delegate: SignupViewModelDelegate?) {
        fatalError("This method must be overridden")
    }
    
    func checkUserName(username: String, complete: CheckUserNameBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    func sendVerifyCode (complete: SendVerificationCodeBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    //
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
    
    func generateKey(complete : GenerateKey) {
        fatalError("This method must be overridden")
    }
    
    func setRecovery(receiveNews:Bool, email : String, displayName : String) {
        fatalError("This method must be overridden")
    }
    
    func setCodeEmail(email : String) {
        fatalError("This method must be overridden")
    }
    
    func setPasswords(loginPwd:String, mailboxPwd:String) {
        fatalError("This method must be overridden")
    }
    
    func setAgreePolicy(isAgree : Bool) {
        fatalError("This method must be overridden")
    }
    
    func setVerifyCode(code : String ) {
        fatalError("This method must be overridden")
    }
    
    func getTimerSet () -> Int {
        fatalError("This method must be overridden")
    }
    
    func getCurrentBit() -> Int32 {
        fatalError("This method must be overridden")
    }
    
    func setBit(bit: Int32) {
        fatalError("This method must be overridden")
    }
}
