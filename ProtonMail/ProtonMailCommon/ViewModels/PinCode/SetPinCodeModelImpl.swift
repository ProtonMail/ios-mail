//
//  SetPinCodeModelImpl.swift
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
import PMKeymaker

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
