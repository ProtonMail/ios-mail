//
//  SignInManager.swift
//  ProtonMail - Created on 18/10/2018.
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
import Keymaker

class SignInManager: NSObject {
    static var shared = SignInManager()
    
    internal func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
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
            afterSignIn()
            guard let mailboxPassword = mailboxpwd else {
                UserTempCachedStatus.restore()
                UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword)
                return
            }
            self.proceedWithMailboxPassword(mailboxPassword, onError: onError)
        }
        
        sharedUserDataService.signIn(username, password: password, twoFACode: cachedTwoCode, ask2fa: ask2fa, onError: onError, onSuccess: success)
    }
    
    internal func isSignedIn() -> Bool {
        return sharedUserDataService.isUserCredentialStored && sharedUserDataService.isMailboxPasswordStored
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
            UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: { })
        }.catch(on: .main) { (error) in
            onError(error as NSError)
            self.clean() // this will happen if fetchUserInfo fails - maybe because of connectivity issues
        }
    }
}
