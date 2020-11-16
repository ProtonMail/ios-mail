//
//  UnlockPinCodeModelImpl.swift
//  ProtonMail - Created on 4/11/16.
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

class UnlockPinCodeModelImpl : PinCodeViewModel {
    
    let titleText : String = LocalString._enter_pin_to_unlock_inbox
    
    var currentStep : PinCodeStep = .enterPin
    
    var enterPin : String = ""
    
    override func needsLogoutConfirmation() -> Bool {
        return true
    }
    
    override func backButtonIcon() -> UIImage {
        let original = UIImage(named: "menu_logout-active")!
        // scale coefficient is a magic number for this specific asset!
        let flipped = UIImage(cgImage: original.cgImage!, scale: 0.7 * original.scale, orientation: .up)
        return flipped
    }
    
    override func title() -> String {
        return titleText
    }
    
    override func cancel() -> String {
        return LocalString._general_confirm_action
    }
    
    override func showConfirm() -> Bool {
        return false
    }
    
    override func confirmString () -> String {
        return ""
    }
    
    override func setCode (_ code : String) -> PinCodeStep {
        switch currentStep {
        case .enterPin:
            enterPin = code
            currentStep = .done
        case .reEnterPin, .done:
            break
        default:
            enterPin = ""
            currentStep = .enterPin
        }
        
        return currentStep
    }
    
    override func isPinMatched(completion: @escaping (Bool)->Void) {
        UnlockManager.shared.match(userInputPin: enterPin) { matched in
            if !matched {
                self.currentStep = .enterPin
            }
            completion(matched)
        }
    }
    
    override func getPinFailedRemainingCount() -> Int {
        return 10 - userCachedStatus.pinFailedCount;
    }
    
    override func getPinFailedError() -> String {
        let c = 10 - userCachedStatus.pinFailedCount
        if c <= 1 {
            return "\(c) \(LocalString._attempt_remaining_until_secure_data_wipe)"
        } else if c < 4 {
            return "\(c) \(LocalString._attempts_remaining_until_secure_data_wipe)"
        }
        return "\(LocalString._incorrect_pin) \(c) \(LocalString._attempts_remaining)"
    }
    
    override func checkTouchID() -> Bool {
        return true
    }
    
    override func done(completion: @escaping (Bool)->Void) {
        completion(false)
    }
}
