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

import ProtonCore_Networking
import ProtonCore_Utilities

class ProtonMailResponseCodeHandler {

    // swiftlint:disable:next function_parameter_count
    func handleProtonResponseCode<T>(
        _ task: URLSessionDataTask?,
        _ response: Either<JSONDictionary, ResponseError>,
        _ responseCode: Int,
        _ method: HTTPMethod,
        _ path: String,
        _ parameters: Any?,
        _ headers: [String: Any]?,
        _ authenticated: Bool,
        _ authRetry: Bool,
        _ authRetryRemains: Int,
        _ authCredential: AuthCredential?,
        _ nonDefaultTimeout: TimeInterval?,
        _ retryPolicy: ProtonRetryPolicy.RetryMode,
        _ completion: PMAPIService.APIResponseCompletion<T>,
        _ humanVerificationHandler: (HTTPMethod, String, Any?, [String: Any]?, Bool, Bool, Int, AuthCredential?, TimeInterval?, ProtonRetryPolicy.RetryMode, URLSessionDataTask?, JSONDictionary, PMAPIService.APIResponseCompletion<T>) -> Void,
        _ deviceVerificationHandler: (HTTPMethod, String, Any?, [String: Any]?, Bool, Bool, Int, AuthCredential?, TimeInterval?, ProtonRetryPolicy.RetryMode, URLSessionDataTask?, JSONDictionary, PMAPIService.APIResponseCompletion<T>) -> Void,
        _ forceUpgradeHandler: (String?) -> Void) where T: APIDecodableResponse {
        if responseCode == APIErrorCode.humanVerificationRequired {
            // human verification required
            humanVerificationHandler(method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, retryPolicy, task, response.responseDictionary, completion)
        } else if responseCode == APIErrorCode.deviceVerificationRequired {
            deviceVerificationHandler(method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, retryPolicy, task, response.responseDictionary, completion)
        } else {
            if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
                forceUpgradeHandler(response.errorMessage)
            }
            switch response {
            case .left(let jsonDictionary): completion.call(task: task, response: .left(jsonDictionary))
            case .right(let responseError): completion.call(task: task, error: responseError as NSError)
            }
        }
    }
}
