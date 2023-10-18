//
//  DeviceVerifyHandler.swift
//  ProtonCore-HumanVerification - Created on 03/21/23.
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
import ProtonCoreAPIClient
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreCrypto

public extension HumanVerifyDelegate {
    
    // This function calculate a device challenge using different challenge types and returns the solved hash in Base64 format.
    func onDeviceVerify(parameters: DeviceVerifyParameters) -> String? {
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            // Determine the challenge type and perform the corresponding hash operation.
            switch parameters.challengeType {
            case .WASM, .Argon2:
                // Solve the hash using Argon2 and return the solved hash in Base64 format.
                let solved = try Hash.Argon2(challengeData: parameters.challengePayload)
                let duration = getEndTime(startTime: startTime)
                return "\(solved), \(duration)"
            case .ECDLP:
                // Solve the hash using ECDLP and return the solved hash in Base64 format.
                let solved = try Hash.ECDLP(challengeData: parameters.challengePayload)
                let duration = getEndTime(startTime: startTime)
                return "\(solved), \(duration)"
            }
        } catch {
            // we don't need to send the hash errors but we should log it.
            // need to add observability here
        }
        
        // Return nil if the hash operation was not successful.
        return nil
    }
    
    func getEndTime(startTime: CFAbsoluteTime) -> Double {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        // Convert to milliseconds and round to two decimal places
        return round(duration * 1000 * 100) / 100
    }
}
