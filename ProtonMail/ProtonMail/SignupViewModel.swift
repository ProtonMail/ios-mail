//
//  SignupViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/18/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


protocol SignupViewModelDelegate{
    func verificationCodeChanged(_ viewModel : SignupViewModel, code : String!)
}


typealias AvailableDomainsComplete = ([String]) -> Void

class SignupViewModel : NSObject {
    func setDelegate (_ delegate: SignupViewModelDelegate?) {
        fatalError("This method must be overridden")
    }
    
    func checkUserName(_ username: String, complete: CheckUserNameBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    func sendVerifyCode (_ type: VerifyCodeType, complete: SendVerificationCodeBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    //
    func setRecaptchaToken (_ token : String, isExpired : Bool ) {
        fatalError("This method must be overridden")
    }
    
    func setPickedUserName (_ username: String, domain:String) {
        fatalError("This method must be overridden")
    }
    
    func isTokenOk() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func createNewUser(_ complete :@escaping CreateUserBlock) {
        fatalError("This method must be overridden")
    }
    
    func generateKey(_ complete :@escaping GenerateKey) {
        fatalError("This method must be overridden")
    }
    
    func setRecovery(_ receiveNews:Bool, email : String, displayName : String) {
        fatalError("This method must be overridden")
    }
    
    func setCodeEmail(_ email : String) {
        fatalError("This method must be overridden")
    }
    
    func setCodePhone(_ phone : String) {
        fatalError("This method must be overridden")
    }
    
    func setEmailVerifyCode(_ code: String) {
        fatalError("This method must be overridden")
    }
    
    func setPhoneVerifyCode (_ code: String) {
        fatalError("This method must be overridden")
    }
    
    func setSinglePassword(_ password: String) {
        fatalError("This method must be overridden")
    }
    
    func setAgreePolicy(_ isAgree : Bool) {
        fatalError("This method must be overridden")
    }
        
    func getTimerSet () -> Int {
        fatalError("This method must be overridden")
    }
    
    func getCurrentBit() -> Int {
        fatalError("This method must be overridden")
    }
    
    func setBit(_ bit: Int) {
        fatalError("This method must be overridden")
    }
    
    func fetchDirect(_ res : @escaping (_ directs:[String]) -> Void) {
        fatalError("This method must be overridden")
    }
    
    func getDirect() -> [String] {
        fatalError("This method must be overridden")
    }
    
    func getDomains(_ complete : @escaping AvailableDomainsComplete) -> Void {
        fatalError("This method must be overridden")
    }
}
