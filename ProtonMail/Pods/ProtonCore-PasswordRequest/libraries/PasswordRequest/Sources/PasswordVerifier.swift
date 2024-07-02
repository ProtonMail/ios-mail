//
//  PasswordVerifier.swift
//  ProtonCore-PasswordRequest - Created on 13.07.23.
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
import ProtonCoreAuthentication
import ProtonCoreNetworking
import ProtonCoreServices

public final class PasswordVerifier {
    private let apiService: APIService
    private let authService: AuthService
    private let responseHandlerData: PMResponseHandlerData?
    private let username: String
    private let srpBuilder: SRPBuilderProtocol
    private let endpoint: Request

    public let authInfo: AuthInfoResponse?
    public let missingScopeMode: MissingScopeMode

    /// Initialize the PasswordVerifier object
    ///
    /// - Parameters:
    ///   - apiService: An instance of the api service to make queries.
    ///   - username: The user's username
    ///   - endpoint: The `Request` endpoint from which the `path` and `method` are used. `UnlockEndpoint` for example should be used to get the `unlock` scope.
    ///   - responseHandlerData: To be set if `headers`, `authenticated`, `authRetry`, `customAuthCredential`, `nonDefaultTimeout` or `retryPolicy` needs to be overwritten. Default values will be used otherwise.
    ///   - authInfo: Set the `authInfo` here if you have them. Otherwise set them to `nil` and use `fetchAuthInfo` to get them.
    ///   - srpBuilder: Used only for testing with dependency injection. Do not override default value otherwise.
    public init(apiService: APIService,
                username: String,
                endpoint: Request,
                missingScopeMode: MissingScopeMode,
                responseHandlerData: PMResponseHandlerData? = nil,
                authInfo: AuthInfoResponse? = nil,
                srpBuilder: SRPBuilderProtocol = SRPBuilder()) {
        self.apiService = apiService
        self.responseHandlerData = responseHandlerData
        self.username = username
        self.endpoint = endpoint
        self.missingScopeMode = missingScopeMode
        self.authInfo = authInfo
        self.srpBuilder = srpBuilder
        authService = .init(api: apiService)
    }

    /// A method to retrieve authInfo for the user.
    public func fetchAuthInfo(completion: @escaping (Result<AuthInfoResponse, AuthErrors>) -> Void) {
        authService.info(username: username, intent: nil) { response in
            switch response {
            case .success(let eitherResponse):
                switch eitherResponse {
                case .left(let authInfoResponse):
                    completion(.success(authInfoResponse))
                case .right:
                    assertionFailure("SSO challenge response should never be returned if the intent is nil")
                    completion(.failure(.switchToSSOError))
                }
            case .failure(let error):
                completion(.failure(.networkingError(error)))
            }
        }
    }

    /// A method to verify the user's password.
    ///
    /// - Parameters:
    ///   - password: The user's password.
    ///   - authInfo: If you don't have the authInfo, call `fetchAuthInfo` first.
    ///   - completion: The completion to be called once the password has been verified.
    public func verifyPassword(password: String, authInfo: AuthInfoResponse, completion: @escaping (Result<SRPClientInfo, AuthErrors>) -> Void) {
        do {
            let srpBuilder = try srpBuilder.buildSRP(username: username, password: password, authInfo: authInfo)
            switch srpBuilder {
            case .failure(let error):
                completion(.failure(error))
            case .success(let srpClientInfo):
                verifyPasswordRequest(srpSession: authInfo.srpSession, srpClientInfo: srpClientInfo, completion: completion)
            }
        } catch let parsingError {
            completion(.failure(.parsingError(parsingError)))
        }
    }

    /// A method that removes the LOCKED and PASSWORD scopes from user's scopes.
    ///
    /// - Parameters:
    ///   - completion: The completion to be called once the scopes have been removed.
    public func lock(completion: @escaping (Result<JSONDictionary, NSError>) -> Void) {
        let lockEnpdoint = LockEndpoint()
        apiService.request(
            method: lockEnpdoint.method,
            path: lockEnpdoint.path,
            parameters: nil,
            headers: nil,
            authenticated: true,
            authRetry: true,
            customAuthCredential: responseHandlerData?.customAuthCredential,
            nonDefaultTimeout: nil,
            retryPolicy: .background,
            jsonCompletion: { _, result in
                completion(result)
            }
        )
    }

    private func verifyPasswordRequest(srpSession: String,
                                       srpClientInfo: SRPClientInfo,
                                       completion: @escaping (Result<SRPClientInfo, AuthErrors>) -> Void) {
        let parameters: [String: String] = [
            "ClientEphemeral": srpClientInfo.clientEphemeral.base64EncodedString(),
            "ClientProof": srpClientInfo.clientProof.base64EncodedString(),
            "SRPSession": srpSession
        ]

        apiService.request(
            method: endpoint.method,
            path: endpoint.path,
            parameters: parameters,
            headers: responseHandlerData?.headers,
            authenticated: responseHandlerData?.authenticated ?? true,
            authRetry: responseHandlerData?.authRetry ?? true,
            customAuthCredential: responseHandlerData?.customAuthCredential,
            nonDefaultTimeout: responseHandlerData?.nonDefaultTimeout,
            retryPolicy: responseHandlerData?.retryPolicy ?? .userInitiated,
            jsonCompletion: { task, result in
                switch result {
                case .success:
                    completion(.success(srpClientInfo))
                case .failure(let error):
                    if error.code == 8002 {
                        completion(.failure(.wrongPassword))
                    } else {
                        completion(.failure(.parsingError(error)))
                    }
                }
            }
        )
    }
}
