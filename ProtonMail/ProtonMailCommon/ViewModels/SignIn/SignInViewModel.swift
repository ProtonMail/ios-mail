//
//  SigninViewModel.swift
//  ProtonMail - Created on 11/4/16.
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

class SignInViewModel : NSObject {
    
    enum SignInComplete {
        case ask2fa
        case error(NSError)
        case ok
        case mbpwd
        case exist
    }

    let usersManager: UsersManager
    let signinManager: SignInManager
    let unlockManager: UnlockManager
    
    init(usersManager: UsersManager) {
        self.usersManager = usersManager
        self.signinManager = sharedServices.get()
        self.unlockManager = sharedServices.get()
    }
    
    func signIn(username: String, password: String, cachedTwoCode: String?, complete: @escaping (SignInComplete)->Void) {
        //Start checking if the user logged in already
        if usersManager.isExist(username) {
            return complete(.exist)
        }
        
        signinManager.signIn(username: username, password: password, cachedTwoCode: cachedTwoCode, ask2fa: {
            complete(.ask2fa)
        }, onError: { (error) in
            complete(.error(error))
        }, afterSignIn: {
            complete(.ok)
        }, requestMailboxPassword: {
            complete(.mbpwd)
        }) {//require mailbox pwd
            self.unlockManager.unlockIfRememberedCredentials(forUser: username) { }
            complete(.ok)
        }
    }
}

