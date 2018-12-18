//
//  SetPinCodeModelImpl.swift
//  ProtonMail - Created on 4/11/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Keymaker

class SetPinCodeModelImpl : PinCodeViewModel {
    
    let StepOneTitle : String = LocalString._enter_your_pin
    let StepTwoTitle : String = LocalString._re_enter_your_pin
    
    var currentStep : PinCodeStep = .enterPin
    
    var enterPin : String = ""
    var reEnterPin : String = "";
    
    override func title() -> String {
        return currentStep == .enterPin ? StepOneTitle : StepTwoTitle
    }
    
    override func cancel() -> String {
        return currentStep == .enterPin ? LocalString._general_create_action : LocalString._general_confirm_action
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
    
    override func isPinMatched(completion: @escaping (Bool)->Void) {
        if !enterPin.isEmpty && !reEnterPin.isEmpty && reEnterPin == enterPin {
            completion(true)
        } else {
            currentStep = .reEnterPin
            completion(false)
        }
    }
    
    override func done(completion: @escaping (Bool)->Void) {
        self.isPinMatched() { matched in
            if matched {
                keymaker.activate(PinProtection(pin: self.enterPin), completion: completion)
            }
        }
    }
    
    override func getPinFailedRemainingCount() -> Int {
        return 11;
    }
    
    override func getPinFailedError() -> String {
        return "The PIN does not match!!!"
    }
}
