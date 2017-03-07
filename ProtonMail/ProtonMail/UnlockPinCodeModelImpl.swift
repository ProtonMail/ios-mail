//
//  UnlockPinCodeModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

class UnlockPinCodeModelImpl : PinCodeViewModel {
    
    let titleText : String = "Enter your PIN to unlock your inbox."
    
    var currentStep : PinCodeStep = .enterPin
    
    var enterPin : String = ""
    
    override func title() -> String {
        return titleText
    }
    
    override func cancel() -> String {
        return "CONFIRM"
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
    
    override func isPinMatched() -> Bool {
        if !enterPin.isEmpty && !userCachedStatus.pinCode.isEmpty && enterPin == userCachedStatus.pinCode {
            userCachedStatus.pinFailedCount = 0;
            return true
        } else {
            userCachedStatus.pinFailedCount += 1
            currentStep = .enterPin
            return false
        }
    }
    
    override func getPinFailedRemainingCount() -> Int {
        return 10 - userCachedStatus.pinFailedCount;
    }
    
    override func getPinFailedError() -> String {
        let c = 10 - userCachedStatus.pinFailedCount
        if c <= 1 {
            return "\(c) attempt remaining until secure data wipe!"
        } else if c < 4 {
            return "\(c) attempts remaining until secure data wipe!"
        }
        return "Incorrect PIN, \(c) attempts remaining"
    }
    
    override func checkTouchID() -> Bool {
        return true
    }
}
