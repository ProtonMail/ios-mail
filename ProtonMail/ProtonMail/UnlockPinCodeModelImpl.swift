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
    
    var currentStep : PinCodeStep = .EnterPin
    
    var enterPin : String = ""
    
    override func title() -> String {
        return titleText
    }
    
    override func cancel() -> String {
        return "Log Out"
    }
    
    override func showConfirm() -> Bool {
        return false
    }
    
    override func confirmString () -> String {
        return ""
    }
    
    override func setCode (code : String) -> PinCodeStep {
        
        switch currentStep {
        case .EnterPin:
            enterPin = code
            currentStep = .Done
        case .ReEnterPin, .Done:
            break
        default:
            enterPin = ""
            currentStep = .EnterPin
        }
        
        return currentStep
    }
    
    override func isPinMatched() -> Bool {
        if !enterPin.isEmpty && !userCachedStatus.pinCode.isEmpty && enterPin == userCachedStatus.pinCode {
            return true
        } else {
            currentStep = .EnterPin
            return false
        }
    }
}