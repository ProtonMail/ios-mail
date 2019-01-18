//
//  SignupViewModel.swift
//  ProtonMail - Created on 1/18/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
