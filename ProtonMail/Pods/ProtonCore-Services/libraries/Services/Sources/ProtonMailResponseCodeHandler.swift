//
//  ProtonMailResponseCodeHandler.swift
//  ProtonCore-Services - Created on 15/03/23.
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
import ProtonCoreFeatureSwitch
import ProtonCoreNetworking
import ProtonCoreUtilities

class ProtonMailResponseCodeHandler {
    func handleProtonResponseCode<T>(
        responseHandlerData: PMResponseHandlerData,
        response: Either<JSONDictionary, ResponseError>,
        responseCode: Int,
        completion: PMAPIService.APIResponseCompletion<T>,
        humanVerificationHandler: (PMResponseHandlerData, PMAPIService.APIResponseCompletion<T>, JSONDictionary) -> Void,
        deviceVerificationHandler: (PMResponseHandlerData, PMAPIService.APIResponseCompletion<T>, JSONDictionary) -> Void,
        missingScopesHandler: (MissingScopeMode, String, PMResponseHandlerData, PMAPIService.APIResponseCompletion<T>) -> Void,
        forceUpgradeHandler: (String?) -> Void) where T: APIDecodableResponse {
        if responseCode == APIErrorCode.humanVerificationRequired {
            // human verification required
            humanVerificationHandler(responseHandlerData, completion, response.responseDictionary)
        } else if responseCode == APIErrorCode.deviceVerificationRequired {
            deviceVerificationHandler(responseHandlerData, completion, response.responseDictionary)
        } else if isMissingScopeError(response: response) && FeatureFactory.shared.isEnabled(.missingScopes), let authCredential = responseHandlerData.customAuthCredential {
            let isAccountRecovery = responseHandlerData.path == "/account/v1/recovery/session/abort"
            missingScopesHandler(
                isAccountRecovery ? .accountRecovery : .default,
                authCredential.userName,
                responseHandlerData,
                completion
            )
        } else {
            if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
                forceUpgradeHandler(response.errorMessage)
            }
            switch response {
            case .left(let jsonDictionary): completion.call(task: responseHandlerData.task, response: .left(jsonDictionary))
            case .right(let responseError): completion.call(task: responseHandlerData.task, error: responseError as NSError)
            }
        }
    }

    private func isMissingScopeError(response: Either<JSONDictionary, ResponseError>) -> Bool {
        if case let .right(error) = response, case .missingScopes = error.details {
            return true
        }

        if case let .left(error) = response, case .missingScopes = error.details {
            return true
        }

        return false
    }
}
