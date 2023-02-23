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
import Network
import TrustKit
import ProtonCore_Doh

public final class TrustKitWrapper {
    
    public static private(set) weak var delegate: TrustKitDelegate?
    public static private(set) var current: TrustKit?

    public static func setUp(delegate: TrustKitDelegate, customConfiguration: Configuration? = nil) {
        let config = configuration(hardfail: true)
        
        let instance = TrustKit(configuration: config)
        
        instance.pinningValidatorCallback = { validatorResult, hostName, policy in
            if validatorResult.evaluationResult != .success,
                validatorResult.finalTrustDecision != .shouldAllowConnection {
                guard validatorResult.evaluationResult != .success,
                      validatorResult.finalTrustDecision != .shouldAllowConnection else { return }

                if hostName.contains(check: ".compute.amazonaws.com") || isIp(hostName) {
                    // hard fail
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

    private static func isIp(_ hostname: String) -> Bool {
        return hostname.withCString { cStringPtr in
            var addr = in6_addr()
            return inet_pton(AF_INET, cStringPtr, &addr) == 1 ||
                   inet_pton(AF_INET6, cStringPtr, &addr) == 1
        }
    }
}

extension String {
    fileprivate func contains(check s: String) -> Bool {
        self.range(of: s, options: NSString.CompareOptions.caseInsensitive) != nil ? true : false
    }
}
