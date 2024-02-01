//
//  ProtonMailAPIService+MissingScopes.swift
//  ProtonCore-Services - Created on 20.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import ProtonCoreLog
import ProtonCoreNetworking

public enum MissingScopeMode {
    case `default`
    case accountRecovery
}

extension PMAPIService {
    func missingScopesHandler<T>(
        missingScopeMode: MissingScopeMode,
        username: String,
        responseHandler: PMResponseHandlerData,
        completion: PMAPIService.APIResponseCompletion<T>) where T: Decodable {
        if !isPasswordVerifyUIPresented.transform({ $0 }) {
            missingPasswordScopesUIHandler(
                missingScopeMode: missingScopeMode,
                username: username,
                responseHandlerData: responseHandler,
                completion: completion
            )
        }
    }

    private func missingPasswordScopesUIHandler<T>(missingScopeMode: MissingScopeMode,
                                                   username: String,
                                                   responseHandlerData: PMResponseHandlerData,
                                                   completion: APIResponseCompletion<T>) where T: Decodable {
        self.isPasswordVerifyUIPresented.mutate { $0 = true }

        missingScopesDelegate?.onMissingScopesHandling(missingScopeMode: missingScopeMode, username: username, responseHandlerData: responseHandlerData) { [weak self] reason in

            guard let self else { return }

            if self.isPasswordVerifyUIPresented.transform({ $0 }) {
                self.isPasswordVerifyUIPresented.mutate { $0 = false }
            }

            switch reason {
            case .unlocked:
                self.repeatRequest(
                    responseHandlerData: responseHandlerData,
                    completion: completion
                )
            case .closed:
                break
            case .closedWithError(let code, let description):
                let newResponseError = APIError.protonMailError(code, localizedDescription: description)
                completion.call(task: responseHandlerData.task, error: newResponseError as NSError)
            }
        }
    }

    private func repeatRequest<T>(responseHandlerData: PMResponseHandlerData,
                                  completion: APIResponseCompletion<T>) where T: Decodable {
        startRequest(
            method: responseHandlerData.method,
            path: responseHandlerData.path,
            parameters: responseHandlerData.parameters,
            headers: responseHandlerData.headers,
            nonDefaultTimeout: responseHandlerData.nonDefaultTimeout,
            retryPolicy: responseHandlerData.retryPolicy,
            onDataTaskCreated: responseHandlerData.onDataTaskCreated,
            completion: completion
        )
    }
}
