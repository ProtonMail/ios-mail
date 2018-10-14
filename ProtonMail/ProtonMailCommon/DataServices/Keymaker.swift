//
//  Keymaker.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 13/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//
//  There is a building. Inside this building there is a level
//  where no elevator can go, and no stair can reach. This level
//  is filled with doors. These doors lead to many places. Hidden
//  places. But one door is special. One door leads to the source.
//

import Foundation
import LocalAuthentication

var keymaker = Keymaker()
class Keymaker: NSObject {
    internal func getUnlockFlow() -> SignInUIFlow {
        if sharedTouchID.showTouchIDOrPin() {
            if userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty {
                return SignInUIFlow.requirePin
            } else {
                //check touch id status
                if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                    return SignInUIFlow.requireTouchID
                } else {
                    return SignInUIFlow.restore
                }
            }
        } else {
            return SignInUIFlow.restore
        }
    }
    
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
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
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
                                            self.decryptPassword(mailboxPassword,
                                                                 requestMailboxPassword: requestMailboxPassword,
                                                                 onError: onError)
                                        } else {
                                            UserTempCachedStatus.restore()
                                            self.loadContent(requestMailboxPassword: requestMailboxPassword)
                                        }
        })
    }
    
    internal func biometricAuthentication(afterBioAuthPassed: @escaping ()->Void,
                                          afterSignIn: @escaping ()->Void)
    {
        let savedEmail = userCachedStatus.codedEmail()
        
        let context = LAContext()
        var error: NSError?
        context.localizedFallbackTitle = ""
        let reasonString = "\(LocalString._general_login): \(savedEmail)"
        
        guard context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) else{
            var alertString : String = "";
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = LocalString._general_touchid_not_enrolled
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = LocalString._general_passcode_not_set
            case -6:
                alertString = error?.localizedDescription ?? LocalString._general_touchid_not_available
                break
            default:
                alertString = LocalString._general_touchid_not_available
            }
            alertString.alertToast()
            return
        }
        
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evalPolicyError in
            DispatchQueue.main.async {
                guard success else {
                    switch evalPolicyError!._code {
                    case LAError.Code.systemCancel.rawValue:
                        LocalString._authentication_was_cancelled_by_the_system.alertToast()
                    case LAError.Code.userCancel.rawValue:
                        PMLog.D("Authentication was cancelled by the user")
                    case LAError.Code.userFallback.rawValue:
                        PMLog.D("User selected to enter custom password")
                    default:
                        PMLog.D("Authentication failed")
                        LocalString._authentication_failed.alertToast()
                    }
                    return
                }
                self.signInIfRememberedCredentials(onSuccess: afterSignIn)
                afterBioAuthPassed()
            }
        }
    }
    
    internal func signInIfRememberedCredentials(onSuccess: ()->Void) {
        if sharedUserDataService.isUserCredentialStored {
            userCachedStatus.lockedApp = false
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
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            self.loadContactsAfterInstall()
        } else {
            requestMailboxPassword()
        }
    }
    
    internal func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
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
    
    private func decryptPassword(_ mailboxPassword: String,
                         requestMailboxPassword: @escaping ()->Void,
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
            self.loadContent(requestMailboxPassword: requestMailboxPassword)
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
        }.catch(on: .main) { (error) in
            fatalError() // FIXME: is this possible at all?
        }
    }
    
}
