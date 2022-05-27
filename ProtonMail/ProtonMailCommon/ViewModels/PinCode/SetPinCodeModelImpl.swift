//
//  SetPinCodeModelImpl.swift
//  Proton Mail - Created on 4/11/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Keymaker

class SetPinCodeModelImpl: PinCodeViewModel {

    var currentStep: PinCodeStep = .enterPin

    var enterPin: String = ""
    var reEnterPin: String = ""

    override func cancel() -> String {
        return currentStep == .enterPin ? LocalString._general_create_action : LocalString._general_confirm_action
    }

    override func setCode (_ code: String) -> PinCodeStep {

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

    override func isPinMatched(completion: @escaping (Bool) -> Void) {
        if !enterPin.isEmpty && !reEnterPin.isEmpty && reEnterPin == enterPin {
            completion(true)
        } else {
            currentStep = .reEnterPin
            completion(false)
        }
    }

    override func done(completion: @escaping (Bool) -> Void) {
        self.isPinMatched { matched in
            if matched {
                keymaker.deactivate(BioProtection())
                keymaker.activate(PinProtection(pin: self.enterPin), completion: completion)
            }
        }
    }

    override func getPinFailedRemainingCount() -> Int {
        return 11
    }

    override func getPinFailedError() -> String {
        return "The PIN does not match!!!"
    }

    override func reset() {
        self.currentStep = .enterPin
        self.enterPin = ""
        self.reEnterPin = ""
    }
}
