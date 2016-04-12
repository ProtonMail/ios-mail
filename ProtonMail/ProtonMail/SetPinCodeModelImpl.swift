//
//  SetPinCodeModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class SetPinCodeModelImpl : PinCodeViewModel {
    
    let StepOneTitle : String = "Enter your PIN"
    let StepTwoTitle : String = "Re-Enter your PIN"
    
    var currentStep : PinCodeStep = .EnterPin
    
    var enterPin : String = ""
    var reEnterPin : String = "";
    
    override func title() -> String {
        return currentStep == .EnterPin ? StepOneTitle : StepTwoTitle
    }
    
    override func cancel() -> String {
        return "Cancel"
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
            currentStep = .ReEnterPin
        case .ReEnterPin:
            reEnterPin = code
            currentStep = .Done
        case .Done:
            break
        default:
            enterPin = ""
            reEnterPin = ""
            currentStep = .EnterPin
        }
        
        return currentStep
    }
    
    override func isPinMatched() -> Bool {
        if !enterPin.isEmpty && !reEnterPin.isEmpty && reEnterPin == enterPin {
            return true
        } else {
            currentStep = .ReEnterPin
            return false
        }
    }
    
    override func done() {
        if self.isPinMatched() {
            userCachedStatus.isPinCodeEnabled = true
            userCachedStatus.pinCode = self.enterPin
        }
    }
}