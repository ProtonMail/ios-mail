//
//  ProtonMailAPIService+RC.swift
//  ProtonCore-Services - Created on 01/27/20.
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
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreUtilities

// MARK: - Handling Refresh Credential
extension APIService {
    public func refreshCredential(_ oldCredential: Credential, completion: @escaping (Result<Credential, ResponseError>) -> Void) {
        // this function becomes the fallback for unit testing. if the client initials the PMAPIService. this code shouldn't be executed.
        // The reason: if we put this interface to protocol APIService. It does not look good because it is a higher-level function than the request/upload.
        //      but if we put the function here the mock won't work and some unit tests will be failed.
        //      so this function will only be for helping the mock sub to be triggered.
        let route = RefreshEndpoint(authCredential: AuthCredential(oldCredential))
        self.perform(request: route) { (_, result: Result<RefreshResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(responseError))
            case .success(let response):
                let credential = Credential(res: response, UID: oldCredential.UID, userName: oldCredential.userName, userID: oldCredential.userID)
                completion(.success(credential))
            }
        }
    }
}

extension PMAPIService {
    // Refresh expired access token using refresh token
    public func refreshCredential(_ oldCredential: Credential, completion: @escaping (Result<Credential, ResponseError>) -> Void) {
        let route = RefreshEndpoint(authCredential: AuthCredential(oldCredential))
        performRequestHavingFetchedCredentials(method: route.method,
                                               path: route.path,
                                               parameters: route.calculatedParameters,
                                               headers: route.header,
                                               authenticated: route.isAuth,
                                               authRetry: route.authRetry,
                                               authRetryRemains: 3,
                                               fetchingCredentialsResult: .found(credentials: AuthCredential(oldCredential)),
                                               nonDefaultTimeout: route.nonDefaultTimeout,
                                               retryPolicy: route.retryPolicy,
                                               onDataTaskCreated: { _ in },
                                               completion: .right({ (task, result: Result<RefreshResponse, APIError>) in
            self.fetchAuthCredentialCompletionBlockBackgroundQueue.async {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .failure(let error):
                    if let responseError = error as? ResponseError {
                        completion(.failure(responseError))
                    } else {
                        let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                        completion(.failure(.init(httpCode: httpCode, responseCode: responseCode,
                                                  userFacingMessage: error.localizedDescription,
                                                  underlyingError: error))
                        )
                    }
                case .success(let response):
                    let credential = Credential(res: response, UID: oldCredential.UID, userName: oldCredential.userName, userID: oldCredential.userID)
                    completion(.success(credential))
                }
            }
        }))
    }
}
