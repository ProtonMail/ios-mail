//
//  SignupViewModel.swift
//  ProtonMail - Created on 1/18/16.
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
    
    func isAccountManager() -> Bool {
        return false
    }
}
