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

class SigninViewModel : NSObject {
    
    enum SigninComplete {
        case ask2fa
        case error(NSError)
        case ok
        case mbpwd
    }

    let usersManager: UsersManager
    
    let unlockManager = UnlockManager(cacheStatus: userCachedStatus, delegate: nil)
    
    init(usersManager: UsersManager) {
        self.usersManager = usersManager
    }
    
    func signIn(username: String, password: String, cachedTwoCode: String?, complete: @escaping (SigninComplete)->Void) {
        let signinManager = SignInManager(usersManager: self.usersManager)
        signinManager.signIn(username: username, password: password, cachedTwoCode: cachedTwoCode, ask2fa: {
            complete(.ask2fa)
        }, onError: { (error) in
            complete(.error(error))
        }, afterSignIn: {
            complete(.ok)
            self.unlockManager.unlockIfRememberedCredentials {
                complete(.mbpwd)
            }
        }, requestMailboxPassword: {
            complete(.mbpwd)
        }) {//require mailbox pwd
            
            self.unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: {})
            
            complete(.ok)
        }
    }
}

