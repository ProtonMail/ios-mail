//
//  PinCodeModel.swift
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

import UIKit

enum PinCodeStep: Int {
    case enterPin = 0
    case reEnterPin = 1
    case unlock = 2
    case done = 3
}

class PinCodeViewModel: NSObject {

    func needsLogoutConfirmation() -> Bool {
        return false
    }

    func backButtonIcon() -> UIImage {
        return UIImage(named: "top_back")!
    }

    func cancel() -> String {
        fatalError("This method must be overridden")
    }

    func setCode (_ code: String) -> PinCodeStep {
        fatalError("This method must be overridden")
    }

    func isPinMatched(completion: @escaping (Bool) -> Void) {
        fatalError("This method must be overridden")
    }

    func getPinFailedRemainingCount() -> Int {
        fatalError("This method must be overridden")
    }

    func getPinFailedError() -> String {
        fatalError("This method must be overridden")
    }

    func done(completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func checkTouchID() -> Bool {
        return false
    }

    func reset() {
        fatalError("This method must be overridden")
    }
}
