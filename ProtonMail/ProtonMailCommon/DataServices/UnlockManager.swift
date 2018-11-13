//
//  UnlockManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 02/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Keymaker

class UnlockManager: NSObject {
    static var shared = UnlockManager()
    
    internal func isUnlocked() -> Bool {
        return keymaker.mainKey != nil
    }
    
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
            guard let _ = key else { return }
            self.unlockIfRememberedCredentials(requestMailboxPassword: afterSignIn)
            afterBioAuthPassed()
        }
    }
    
    internal func initiateUnlock(flow signinFlow: SignInUIFlow,
                                 requestPin: @escaping ()->Void,
                                 onRestore: @escaping ()->Void,
                                 afterSignIn: @escaping ()->Void)
    {
        switch signinFlow {
        case .requirePin:
            requestPin()
            
        case .requireTouchID:
            self.biometricAuthentication(afterBioAuthPassed: onRestore, afterSignIn: afterSignIn)
            
        case .restore:
            self.unlockIfRememberedCredentials(requestMailboxPassword: afterSignIn)
            onRestore()
        }
    }
    
    internal func unlockIfRememberedCredentials(requestMailboxPassword: ()->Void) {
        guard sharedUserDataService.isUserCredentialStored else {
            #if !APP_EXTENSION
            SignInManager.shared.clean()
            #endif
            return
        }
        
        guard sharedUserDataService.isMailboxPasswordStored else {
            requestMailboxPassword()
            return
        }
        #if !APP_EXTENSION
        UserTempCachedStatus.clearFromKeychain()
        userCachedStatus.pinFailedCount = 0
        self.updateUserData()
        sharedMessageDataService.injectTransientValuesIntoMessages()
        ServicePlanDataService.shared.updateServicePlans()
        NotificationCenter.default.post(name: Notification.Name.didUnlock, object: nil)
        #endif
    }
    
    
    #if !APP_EXTENSION
    private func updateUserData() { // previously this method was called loadContactsAfterInstall()
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
    #endif
}
