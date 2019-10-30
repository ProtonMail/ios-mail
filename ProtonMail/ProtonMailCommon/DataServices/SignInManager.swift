//
//  SignInManager.swift
//  ProtonMail - Created on 18/10/2018.
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
import Keymaker

class SignInManager: NSObject {
    static var shared = SignInManager()
    
    internal func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    internal func isSignedIn() -> Bool {
        return sharedUserDataService.isUserCredentialStored && sharedUserDataService.isMailboxPasswordStored
    }
    
#if !APP_EXTENSION
    internal func signIn(username: String,
                         password: String,
                         cachedTwoCode: String?,
                         ask2fa: @escaping ()->Void,
                         onError: @escaping (NSError)->Void,
                         afterSignIn: @escaping ()->Void,
                         requestMailboxPassword: @escaping ()->Void)
    {
        self.clean()
        
        let success: (String?)->Void = { mailboxpwd in
            guard let mailboxPassword = mailboxpwd else {
                UserTempCachedStatus.restore()
                UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword)
                afterSignIn()
                return
            }
            self.proceedWithMailboxPassword(mailboxPassword, onError: onError)
        }
        
        sharedUserDataService.signIn(username, password: password, twoFACode: cachedTwoCode, ask2fa: ask2fa, onError: onError, onSuccess: success)
    }
    
    internal func mailboxPassword(from cleartextPassword: String) -> String {
        var mailboxPassword = cleartextPassword
        if let keysalt = AuthCredential.getKeySalt(), !keysalt.isEmpty {
            let keysalt_byte: Data = keysalt.decodeBase64()
            mailboxPassword = PasswordUtils.getMailboxPassword(cleartextPassword, salt: keysalt_byte)
        }
        return mailboxPassword
    }
    
    internal func proceedWithMailboxPassword(_ mailboxPassword: String,
                                  onError: @escaping (NSError)->Void)
    {
        guard let privateKey = AuthCredential.getPrivateKey(),
            sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: privateKey) else
        {
            onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._the_mailbox_password_is_incorrect))
            return
        }
        
        if !sharedUserDataService.isSet {
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil)
        }
        
        do {
            try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: true)
        } catch let ex as NSError {
            onError(ex)
            return
        }
        
        sharedLabelsDataService.fetchLabels()
        sharedUserDataService.fetchUserInfo().done(on: .main) { info in
            guard let info = info else {
                onError(NSError.unknowError())
                return
            }
            
            guard info.delinquent < 3 else {
                onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._general_account_disabled_non_payment))
                return
            }
            
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil)
            UserTempCachedStatus.restore()
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: { })
        }.catch(on: .main) { (error) in
            onError(error as NSError)
            self.clean() // this will happen if fetchUserInfo fails - maybe because of connectivity issues
        }
    }
#endif
}
