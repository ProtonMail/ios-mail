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
    
    internal func biometricAuthentication(requestMailboxPassword: @escaping ()->Void) {
        keymaker.obtainMainKey(with: BioProtection()) { key in
            guard let _ = key else { return }
            self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword)
        }
    }
    
    internal func biometricAuthentication(afterBioAuthPassed: @escaping ()->Void) {
        keymaker.obtainMainKey(with: BioProtection()) { key in
            guard let _ = key else { return }
            afterBioAuthPassed()
        }
    }
    
    internal func initiateUnlock(flow signinFlow: SignInUIFlow,
                                 requestPin: @escaping ()->Void,
                                 requestMailboxPassword: @escaping ()->Void)
    {
        switch signinFlow {
        case .requirePin:
            requestPin()
            
        case .requireTouchID:
            self.biometricAuthentication(requestMailboxPassword: requestMailboxPassword) // will send message
            
        case .restore:
            self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword)
        }
    }
    
    internal func unlockIfRememberedCredentials(requestMailboxPassword: ()->Void) {
        guard sharedUserDataService.isUserCredentialStored else {
            #if !APP_EXTENSION
            SignInManager.shared.clean()
            #endif
            return
        }
        
        guard sharedUserDataService.isMailboxPasswordStored else { // this will provoke mainKey obtention
            requestMailboxPassword()
            return
        }
        
        userCachedStatus.pinFailedCount = 0
        
        #if !APP_EXTENSION
        UserTempCachedStatus.clearFromKeychain()
        sharedMessageDataService.injectTransientValuesIntoMessages()
        self.updateUserData()
        #endif
        
        NotificationCenter.default.post(name: Notification.Name.didUnlock, object: nil)
    }
    
    
    #if !APP_EXTENSION
    // TODO: verify if some of these operations can be optimized
    private func updateUserData() { // previously this method was called loadContactsAfterInstall()
        ServicePlanDataService.shared.updateServicePlans()
        ServicePlanDataService.shared.updateCurrentSubscription()
        StoreKitManager.default.processAllTransactions()
        
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
