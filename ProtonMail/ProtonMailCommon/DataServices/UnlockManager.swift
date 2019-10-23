//
//  UnlockManager.swift
//  ProtonMail - Created on 02/11/2018.
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
import LocalAuthentication

class UnlockManager: NSObject {
    static var shared = UnlockManager()
    
    internal func isUnlocked() -> Bool {
        return self.validate(mainKey: keymaker.mainKey)
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
        keymaker.obtainMainKey(with: PinProtection(pin: userInputPin)) { key in
            guard self.validate(mainKey: key) else {
                userCachedStatus.pinFailedCount += 1
                completion(false)
                return
            }
            
            userCachedStatus.pinFailedCount = 0;
            completion(true)
        }
    }
    
    private func validate(mainKey: Keymaker.Key?) -> Bool {
        guard let _ = mainKey else { // currently enough: key is Array and will be nil in case it was unlocked incorrectly
            keymaker.lockTheApp() // remember to remove invalid key in case validation will become more complex
            return false
        }
        return true
    }
    
    
    internal func biometricAuthentication(requestMailboxPassword: @escaping ()->Void) {
        self.biometricAuthentication(afterBioAuthPassed: { self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword) })
    }
    
    var isRequestingBiometricAuthentication: Bool = false
    internal func biometricAuthentication(afterBioAuthPassed: @escaping ()->Void) {
        var error: NSError?
        guard LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            PMLog.D("LAContext canEvaluatePolicy is false, error: " + String(describing: error?.localizedDescription))
            assert(false, "LAContext canEvaluatePolicy is false")
            return
        }
        
        guard !self.isRequestingBiometricAuthentication else { return }
        self.isRequestingBiometricAuthentication = true
        keymaker.obtainMainKey(with: BioProtection()) { key in
            defer {
                self.isRequestingBiometricAuthentication = false
            }
            guard self.validate(mainKey: key) else { return }
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
        guard keymaker.mainKeyExists(),
            sharedUserDataService.isUserCredentialStored else
        {
            #if !APP_EXTENSION
            SignInManager.shared.clean()
            #endif
            return
        }
        
        guard sharedUserDataService.mailboxPassword != nil else { // this will provoke mainKey obtention
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
                PMLog.D("Contacts count: \(contacts?.count)")
            }
        }
    }
    #endif
}
