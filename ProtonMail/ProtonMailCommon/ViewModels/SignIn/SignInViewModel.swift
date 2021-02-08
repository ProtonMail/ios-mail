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
import PromiseKit
import DeviceCheck

class SignInViewModel : NSObject {
    
    enum SignInComplete {
        case ask2fa
        case error(NSError)
        case ok
        case mbpwd
        case exist
        case limit
    }

    let usersManager: UsersManager
    let signinManager: SignInManager
    let unlockManager: UnlockManager
    var username: String? // value to pre-fill username in the View
    
    init(usersManager: UsersManager, username: String? = nil) {
        self.usersManager = usersManager
        self.signinManager = sharedServices.get()
        self.unlockManager = sharedServices.get()
        self.username = username
    }
    
    func signIn(username: String, password: String, cachedTwoCode: String?, faillogout: Bool, complete: @escaping (SignInComplete)->Void) {
        //Start checking if the user logged in already
        if usersManager.isExist(userName: username) {
            return complete(.exist)
        }
        
        signinManager.signIn(username: username, password: password, noKeyUser: false, cachedTwoCode: cachedTwoCode, faillogout: faillogout, ask2fa: {
            complete(.ask2fa)
        }, onError: { (error) in
            complete(.error(error))
        }, reachLimit: {
            complete(.limit)
        }, exist: {
            complete(.exist)
        }, afterSignIn: {
            complete(.ok)
        }, requestMailboxPassword: {
            complete(.mbpwd)
        }) {//require mailbox pwd
            self.unlockManager.unlockIfRememberedCredentials(forUser: username, requestMailboxPassword: { })
            complete(.ok)
        }
    }
    
    enum TokenError : Error {
        case unsupport
        case empty
        case error
    }
    
    func generateToken() -> Promise<String> {
        let currentDevice = DCDevice.current
        if currentDevice.isSupported {
            let deferred = Promise<String>.pending()
            currentDevice.generateToken(completionHandler: { (data, error) in
                if let tokenData = data {
                    deferred.resolver.fulfill(tokenData.base64EncodedString())
                } else if let error = error {
                    deferred.resolver.reject(error)
                } else {
                    deferred.resolver.reject(TokenError.empty)
                }
            })
            return deferred.promise
        }
        
        #if Enterprise
        return Promise<String>.value("EnterpriseBuildInternalTestOnly".encodeBase64())
        #else
        return Promise<String>.init(error: TokenError.unsupport)
        #endif
    }
    
    func shouldShowUpdateAlert() -> Bool {
        return false
    }
    
    func setiOS10AlertIsShown() {
        userCachedStatus.iOS10AlertIsShown = true
    }
}

