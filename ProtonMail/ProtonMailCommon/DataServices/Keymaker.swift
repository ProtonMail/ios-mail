//
//  Keymaker.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 13/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Crashlytics
import LocalAuthentication
import MBProgressHUD


typealias SIVController = SIV&UIViewController
protocol SIV: class {
    func ShowLoginViews()
    func setupView()
    func showTouchID(_ animated: Bool)
    
    var showingTouchID: Bool { get set }
    var isRemembered: Bool { get set }
    var kSegueTo2FACodeSegue: String { get }
    var kMailboxSegue: String { get }
    var kSegueToPinCodeViewNoAnimation: String { get }
}

var keymaker = Keymaker()
class Keymaker: NSObject {
    var cachedTwoCode : String?
    
    func getViewFlow(_ vc: SIVController) -> SignInUIFlow {
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
    
    func processViewFlow(_ signinFlow: SignInUIFlow,
                         _ vc: SIVController)
    {
        switch signinFlow {
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            vc.performSegue(withIdentifier: vc.kSegueToPinCodeViewNoAnimation, sender: vc)
            
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            vc.showTouchID(false)
            self.authenticateUser(vc)
            
        case .restore:
            self.signInIfRememberedCredentials(vc)
            vc.setupView();
        }
    }
    
    func signIn(username: String,
                password: String,
                vc: SIVController)
    {
        MBProgressHUD.showAdded(to: vc.view, animated: true)
        vc.isRemembered = true
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            clean();
        }
        
        SignInViewController.isComeBackFromMailbox = false
        
        //need pass twoFACode
        sharedUserDataService.signIn(username, password: password, twoFACode: cachedTwoCode,
                                     ask2fa: {
                                        //2fa
                                        MBProgressHUD.hide(for: vc.view, animated: true)
                                        vc.performSegue(withIdentifier: vc.kSegueTo2FACodeSegue, sender: vc)
        },
                                     onError: { (error) in
                                        //error
                                        self.cachedTwoCode = nil
                                        MBProgressHUD.hide(for: vc.view, animated: true)
                                        PMLog.D("error: \(error)")
                                        vc.ShowLoginViews();
                                        if !error.code.forceUpgrade {
                                            let alertController = error.alertController()
                                            alertController.addOKAction()
                                            vc.present(alertController, animated: true, completion: nil)
                                        }
        },
                                     onSuccess: { (mailboxpwd) in
                                        //ok
                                        self.cachedTwoCode = nil
                                        MBProgressHUD.hide(for: vc.view, animated: true)
                                        if mailboxpwd != nil {
                                            self.decryptPassword(mailboxpwd!, vc: vc)
                                        } else {
                                            self.restoreBackup()
                                            self.loadContent(vc)
                                        }
        })
    }
    
    func authenticateUser(_ vc: SIVController) {
        if !vc.showingTouchID {
            vc.showingTouchID = true
        } else {
            return
        }
        let savedEmail = userCachedStatus.codedEmail()
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "\(LocalString._general_login): \(savedEmail)"
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) in
                vc.showingTouchID = false
                if success {
                    DispatchQueue.main.async {
                        self.signInIfRememberedCredentials(vc)
                        vc.setupView()
                    }
                }
                else{
                    DispatchQueue.main.async {
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
                    }
                }
            })
        }
        else{
            vc.showingTouchID = false
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = LocalString._general_touchid_not_enrolled
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = LocalString._general_passcode_not_set
            case -6:
                alertString = error?.localizedDescription ?? LocalString._general_touchid_not_available
                break
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = LocalString._general_touchid_not_available
            }
            alertString.alertToast()
        }
    }
    
    func signInIfRememberedCredentials(_ vc: SIVController) {
        if sharedUserDataService.isUserCredentialStored {
            userCachedStatus.lockedApp = false
            sharedUserDataService.isSignedIn = true
            vc.isRemembered = true
            
            self.loadContent(vc)
        }
        else
        {
            clean()
        }
    }
    
    fileprivate func loadContent(_ vc: SIVController) {
        logUser()
        if sharedUserDataService.isMailboxPasswordStored {
            UserTempCachedStatus.clearFromKeychain()
            userCachedStatus.pinFailedCount = 0;
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: vc)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            loadContactsAfterInstall()
        } else {
            vc.performSegue(withIdentifier: vc.kMailboxSegue, sender: vc)
        }
    }
    
    func logUser() {
        if  let username = sharedUserDataService.username {
            Crashlytics.sharedInstance().setUserIdentifier(username)
            Crashlytics.sharedInstance().setUserName(username)
        }
    }
    
    func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    func loadContactsAfterInstall() {
        ServicePlanDataService.shared.updateCurrentSubscription()
        sharedUserDataService.fetchUserInfo().done { (_) in
            
            }.catch { (_) in
                
        }
        //TODO:: here need to be changed
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }
    
    func decryptPassword(_ mailboxPassword:String!,
                         vc: SIVController)
    {
        vc.isRemembered = true
        if sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: vc.isRemembered)
                (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                do {
                    try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: vc.isRemembered)
                    MBProgressHUD.showAdded(to: vc.view, animated: true)
                    sharedLabelsDataService.fetchLabels()
                    ServicePlanDataService.shared.updateCurrentSubscription()
                    sharedUserDataService.fetchUserInfo().done(on: .main) { info in
                        MBProgressHUD.hide(for: vc.view, animated: true)
                        if info != nil {
                            if info!.delinquent < 3 {
                                userCachedStatus.pinFailedCount = 0;
                                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: vc.isRemembered)
                                self.restoreBackup()
                                self.loadContent(vc)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: vc)
                            } else {
                                let alertController = LocalString._general_account_disabled_non_payment.alertController()
                                alertController.addAction(UIAlertAction.okAction({ (action) -> Void in
                                    let _ = vc.navigationController?.popViewController(animated: true)
                                }))
                                vc.present(alertController, animated: true, completion: nil)
                            }
                        } else {
                            let alertController = NSError.unknowError().alertController()
                            alertController.addOKAction()
                            vc.present(alertController, animated: true, completion: nil)
                        }
                        }.catch(on: .main) { (error) in
                            MBProgressHUD.hide(for: vc.view, animated: true)
                            if let error = error as NSError? {
                                let alertController = error.alertController()
                                alertController.addOKAction()
                                vc.present(alertController, animated: true, completion: nil)
                                if error.domain == APIServiceErrorDomain && error.code == APIErrorCode.AuthErrorCode.localCacheBad {
                                    let _ = vc.navigationController?.popViewController(animated: true)
                                }
                            }
                    }
                } catch let ex as NSError {
                    MBProgressHUD.hide(for: vc.view, animated: true)
                    let message = (ex.userInfo["MONExceptionReason"] as? String) ?? LocalString._the_mailbox_password_is_incorrect
                    let alertController = UIAlertController(title: LocalString._incorrect_password, message: NSLocalizedString(message, comment: ""),preferredStyle: .alert)
                    alertController.addOKAction()
                    vc.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: LocalString._incorrect_password, message: LocalString._the_mailbox_password_is_incorrect, preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func restoreBackup () {
        UserTempCachedStatus.restore()
    }
}
