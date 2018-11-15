//
//  SignInManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
        return sharedUserDataService.isUserCredentialStored
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
        guard sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) else {
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
        }
        
        sharedLabelsDataService.fetchLabels()
        ServicePlanDataService.shared.updateCurrentSubscription()
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
            self.clean() // this will happen if fetchUserInfo fails - maybe because of connectivity issues
        }
    }
}
