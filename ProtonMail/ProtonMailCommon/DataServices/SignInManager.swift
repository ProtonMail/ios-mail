//
//  SignInManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import LocalAuthentication

var sharedSignIn = SignInManager.shared
class SignInManager: NSObject {
    static var shared = SignInManager()
    
    internal func getUnlockFlow() -> SignInUIFlow {
        if userCachedStatus.isPinCodeEnabled {
            return SignInUIFlow.requirePin
        }
        if userCachedStatus.isTouchIDEnabled {
            return SignInUIFlow.requireTouchID
        }
        return SignInUIFlow.restore
    }
    
    internal func match(userInputPin: String, completion: @escaping (Bool)->Void) {
        guard !userInputPin.isEmpty else {
            userCachedStatus.pinFailedCount += 1
            completion(false)
            return
        }
        let _ = keymaker.obtainMainKey(with: PinProtection(pin: userInputPin)) { key in
            guard let _ = key else {
                userCachedStatus.pinFailedCount += 1
                completion(false)
                return
            }
            userCachedStatus.pinFailedCount = 0;
            completion(true)
        }
    }
    
    internal func biometricAuthentication(afterBioAuthPassed: @escaping ()->Void,
                                          afterSignIn: @escaping ()->Void)
    {
        keymaker.obtainMainKey(with: BioProtection()) { key in
            guard let _ = key else {
                #if !APP_EXTENSION
                LocalString._authentication_failed.alertToast()
                #endif
                return
            }
            
            #if !APP_EXTENSION
            self.signInIfRememberedCredentials(onSuccess: afterSignIn)
            #endif
            afterBioAuthPassed()
        }
    }
}

#if !APP_EXTENSION
extension SignInManager {
    internal func unlock(accordingToFlow signinFlow: SignInUIFlow,
                         requestPin: @escaping ()->Void,
                         onRestore: @escaping ()->Void,
                         afterSignIn: @escaping ()->Void)
    {
        switch signinFlow {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            requestPin()
            
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            self.biometricAuthentication(afterBioAuthPassed: onRestore, afterSignIn: afterSignIn)
            
        case .restore:
            self.signInIfRememberedCredentials(onSuccess: afterSignIn)
            onRestore()
        }
    }
    
    internal func signIn(username: String,
                         password: String,
                         cachedTwoCode: String?,
                         ask2fa: @escaping ()->Void,
                         onError: @escaping (NSError)->Void,
                         afterSignIn: @escaping ()->Void,
                         requestMailboxPassword: @escaping ()->Void)
    {
        if (userCachedStatus.isTouchIDEnabled) {
            self.clean()
        }
        
        //need pass twoFACode
        sharedUserDataService.signIn(username,
                                     password: password,
                                     twoFACode: cachedTwoCode,
                                     ask2fa: ask2fa,
                                     onError: onError,
                                     onSuccess: { (mailboxpwd) in
                                        afterSignIn()
                                        if let mailboxPassword = mailboxpwd {
                                            self.decryptPassword(mailboxPassword, onError: onError)
                                        } else {
                                            UserTempCachedStatus.restore()
                                            self.loadContent(requestMailboxPassword: requestMailboxPassword)
                                        }
        })
    }
    
    internal func isSignedIn() -> Bool {
        return sharedUserDataService.isUserCredentialStored
    }
    
    internal func signInIfRememberedCredentials(onSuccess: ()->Void) {
        if sharedUserDataService.isUserCredentialStored {
            sharedUserDataService.isSignedIn = true
            self.loadContent(requestMailboxPassword: onSuccess)
        } else {
            self.clean()
        }
    }
    
    private func loadContent(requestMailboxPassword: ()->Void) {
        if sharedUserDataService.isMailboxPasswordStored {
            UserTempCachedStatus.clearFromKeychain()
            userCachedStatus.pinFailedCount = 0
            self.loadContactsAfterInstall()
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
        } else {
            requestMailboxPassword()
        }
    }
    
    internal func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
        keymaker.wipeMainKey()
    }
    
    private func loadContactsAfterInstall() {
        ServicePlanDataService.shared.updateCurrentSubscription()
        sharedUserDataService.fetchUserInfo().done { _ in }.catch { _ in }
        
        //TODO:: here need to be changed
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }
    
    internal func mailboxPassword(from cleartextPassword: String) -> String {
        var mailboxPassword = cleartextPassword
        if let keysalt = AuthCredential.getKeySalt(), !keysalt.isEmpty {
            let keysalt_byte: Data = keysalt.decodeBase64()
            mailboxPassword = PasswordUtils.getMailboxPassword(cleartextPassword, salt: keysalt_byte)
        }
        return mailboxPassword
    }
    
    internal func decryptPassword(_ mailboxPassword: String,
                                  onError: @escaping (NSError)->Void)
    {
        let isRemembered = true
        guard sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) else {
            onError(NSError.init(domain: "", code: 0, localizedDescription: LocalString._the_mailbox_password_is_incorrect))
            return
        }
        
        guard !sharedUserDataService.isSet else {
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: isRemembered)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            return
        }
        
        do {
            try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: isRemembered)
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
            
            userCachedStatus.pinFailedCount = 0;
            sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: isRemembered)
            UserTempCachedStatus.restore()
            self.loadContent(requestMailboxPassword: { })
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
        }.catch(on: .main) { (error) in
                fatalError() // FIXME: is this possible at all?
        }
    }
    
}
#endif
