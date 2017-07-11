//
//  SignupViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 1/18/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


public protocol SignupViewModelDelegate{
    func verificationCodeChanged(_ viewModel : SignupViewModel, code : String!)
}


public typealias AvailableDomainsComplete = ([String]) -> Void

open class SignupViewModel : NSObject {
    public func setDelegate (_ delegate: SignupViewModelDelegate?) {
        fatalError("This method must be overridden")
    }
    
    public func checkUserName(_ username: String, complete: CheckUserNameBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    public func sendVerifyCode (_ type: VerifyCodeType, complete: SendVerificationCodeBlock!) -> Void {
        fatalError("This method must be overridden")
    }
    
    //
    public func setRecaptchaToken (_ token : String, isExpired : Bool ) {
        fatalError("This method must be overridden")
    }
    
    public func setPickedUserName (_ username: String, domain:String) {
        fatalError("This method must be overridden")
    }
    
    public func isTokenOk() -> Bool {
        fatalError("This method must be overridden")
    }
    
    public func createNewUser(_ complete :@escaping CreateUserBlock) {
        fatalError("This method must be overridden")
    }
    
    public func generateKey(_ complete :@escaping GenerateKey) {
        fatalError("This method must be overridden")
    }
    
    public func setRecovery(_ receiveNews:Bool, email : String, displayName : String) {
        fatalError("This method must be overridden")
    }
    
    public func setCodeEmail(_ email : String) {
        fatalError("This method must be overridden")
    }
    
    public func setCodePhone(_ phone : String) {
        fatalError("This method must be overridden")
    }
    
    public func setEmailVerifyCode(_ code: String) {
        fatalError("This method must be overridden")
    }
    
    public func setPhoneVerifyCode (_ code: String) {
        fatalError("This method must be overridden")
    }
    
    public func setSinglePassword(_ password: String) {
        fatalError("This method must be overridden")
    }
    
    public func setAgreePolicy(_ isAgree : Bool) {
        fatalError("This method must be overridden")
    }
        
    public func getTimerSet () -> Int {
        fatalError("This method must be overridden")
    }
    
    public func getCurrentBit() -> Int32 {
        fatalError("This method must be overridden")
    }
    
    public func setBit(_ bit: Int32) {
        fatalError("This method must be overridden")
    }
    
    public func fetchDirect(_ res : @escaping (_ directs:[String]) -> Void) {
        fatalError("This method must be overridden")
    }
    
    public func getDirect() -> [String] {
        fatalError("This method must be overridden")
    }
    
    public func getDomains(_ complete : @escaping AvailableDomainsComplete) -> Void {
        fatalError("This method must be overridden")
    }
}
