//
//  SetPinCodeModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/11/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

class SetPinCodeModelImpl : PinCodeViewModel {
    
    let StepOneTitle : String = NSLocalizedString("Enter your PIN", comment: "set pin title")
    let StepTwoTitle : String = NSLocalizedString("Re-Enter your PIN", comment: "set pin title")
    
    var currentStep : PinCodeStep = .enterPin
    
    var enterPin : String = ""
    var reEnterPin : String = "";
    
    override func title() -> String {
        return currentStep == .enterPin ? StepOneTitle : StepTwoTitle
    }
    
    override func cancel() -> String {
        return currentStep == .enterPin ? NSLocalizedString("CREATE", comment: "setup pin action") : NSLocalizedString("CONFIRM", comment: "setup pin action")
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
            currentStep = .reEnterPin
        case .reEnterPin:
            reEnterPin = code
            currentStep = .done
        case .done:
            break
        default:
            enterPin = ""
            reEnterPin = ""
            currentStep = .enterPin
        }
        
        return currentStep
    }
    
    override func isPinMatched() -> Bool {
        if !enterPin.isEmpty && !reEnterPin.isEmpty && reEnterPin == enterPin {
            return true
        } else {
            currentStep = .reEnterPin
            return false
        }
    }
    
    override func done() {
        if self.isPinMatched() {
            userCachedStatus.isPinCodeEnabled = true
            userCachedStatus.pinCode = self.enterPin
        }
    }
    
    override func getPinFailedRemainingCount() -> Int {
        return 11;
    }
    
    override func getPinFailedError() -> String {
        return "The PIN does not match!!!"
    }
}
