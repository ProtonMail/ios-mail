//
//  TrustKitWrapper.swift
//  ProtonCore-Doh - Created on 24/03/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Doh
import TrustKit

final class TrustKitWrapper {
    
    static private weak var delegate: TrustKitDelegate?
    static private(set) var current: TrustKit?

    static func setUp(delegate: TrustKitDelegate, customConfiguration: Configuration? = nil) {

        let config = configuration(hardfail: true)
        
        let instance = TrustKit(configuration: config)
        
        instance.pinningValidatorCallback = { validatorResult, hostName, policy in
            if validatorResult.evaluationResult != .success,
                validatorResult.finalTrustDecision != .shouldAllowConnection {
                guard validatorResult.evaluationResult != .success,
                      validatorResult.finalTrustDecision != .shouldAllowConnection else { return }

                if hostName.contains(check: ".compute.amazonaws.com") {
                    //hard fail
                    delegate.onTrustKitValidationError(.hardfailed)
                } else {
                    // need to show a alert let user to ignore the alert or not.
                    delegate.onTrustKitValidationError(.failed)
                }
            }
        }
        self.delegate = delegate
        self.current = instance
    }
}

extension String {
    fileprivate func contains(check s: String) -> Bool {
        self.range(of: s, options: NSString.CompareOptions.caseInsensitive) != nil ? true : false
    }
}
