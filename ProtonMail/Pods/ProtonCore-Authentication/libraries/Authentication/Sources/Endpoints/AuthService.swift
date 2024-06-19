//
//  AuthService.swift
//  ProtonCore-Authentication - Created on 20/02/2020.
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
import ProtonCoreServices
import ProtonCoreAPIClient
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreFeatureFlags
import ProtonCoreUtilities
import ProtonCoreObservability
import ProtonCoreLog

public class AuthService: Client {
    public var apiService: APIService
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol

    public init(api: APIService, featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared) {
        self.apiService = api
        self.featureFlagsRepository = featureFlagsRepository
    }

    func ssoAuthentication(ssoResponseToken: SSOResponseToken, complete: @escaping(_ response: Result<AuthService.AuthRouteResponse, ResponseError>) -> Void) {
        let endpoint = SSOEndpoint(ssoResponseToken: ssoResponseToken)
        apiService.perform(request: endpoint) { (_, result: Result<AuthService.AuthRouteResponse, ResponseError>) in
            switch result {
            case .success(let authRouteResponse):
                ObservabilityEnv.report(.ssoAuthWithTokenTotalEvent(status: .http2xx))
                complete(.success(authRouteResponse))
            case .failure(let error):
                ObservabilityEnv.report(.ssoAuthWithTokenTotalEvent(error: error))
                complete(.failure(error))
            }
        }
    }

    public func info(username: String? = nil, intent: Intent? = nil, complete: @escaping(_ response: Result<Either<AuthInfoResponse, SSOChallengeResponse>, ResponseError>) -> Void) {
        var endpoint: InfoEndpoint

        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.externalSSO, reloadValue: true),
           let intent = intent {
            switch intent {
            case .sso:
                endpoint = InfoEndpoint(username: username, intent: .sso)
                apiService.perform(request: endpoint) { (_, result: Result<SSOChallengeResponse, ResponseError>) in
                    switch result {
                    case .success(let response):
                        ObservabilityEnv.report(.ssoObtainChallengeToken(status: .http2xx))
                        complete(.success(.right(response)))
                    case .failure(let error):
                        ObservabilityEnv.report(.ssoObtainChallengeToken(error: error))
                        complete(.failure(error))
                    }
                }
            case .proton:
                endpoint = InfoEndpoint(username: username, intent: .proton)
                apiService.perform(request: endpoint) { (_, result: Result<AuthInfoResponse, ResponseError>) in
                    switch result {
                    case .success(let response):
                        complete(.success(.left(response)))
                    case .failure(let error):
                        complete(.failure(error))
                    }
                }
            case .auto:
                endpoint = InfoEndpoint(username: username, intent: .auto)
                apiService.perform(request: endpoint, jsonDictionaryCompletion: { _, result in
                    switch result {
                    case .success(let response):
                        do {
                            let ssoResponse = try SSOChallengeResponse(response)
                            ObservabilityEnv.report(.ssoObtainChallengeToken(status: .http2xx))
                            complete(.success(.right(ssoResponse)))
                        } catch {
                            do {
                                let authInfoResponse = try AuthInfoResponse(response)
                                complete(.success(.left(authInfoResponse)))
                            } catch {
                                complete(.failure(ResponseError(httpCode: nil, responseCode: 2002, userFacingMessage: "Response is neither SSOChallenge, nor AuthInfoResponse", underlyingError: nil)))
                            }
                        }
                    case .failure(let error):
                        complete(.failure(error))
                    }
                })
            }
        } else {
            endpoint = InfoEndpoint(username: username)
            apiService.perform(request: endpoint) { (_, result: Result<AuthInfoResponse, ResponseError>) in
                switch result {
                case .success(let response):
                    complete(.success(.left(response)))
                case .failure(let error):
                    complete(.failure(error))
                }
            }
        }
    }

    func auth(username: String,
              ephemeral: Data,
              proof: Data,
              srpSession: String,
              challenge: ChallengeProperties?,
              complete: @escaping(_ response: Result<AuthService.AuthRouteResponse, ResponseError>) -> Void) {
        var route = AuthEndpoint(data: .left(.init(username: username, ephemeral: ephemeral, proof: proof, srpSession: srpSession, challenge: challenge)))

        let service = self.apiService
        service.fetchAuthCredentials { result in
            switch result {
            case .found(let credential):
                route.authCredential = credential

                // We are authenticating the user. If the current credentials are not for unauth session,
                // this authentication is done in the session of already authenticated user.
                // If this already authenticated user is the same as the one we authenticate now, we basically do re-login.
                // There's not really an usecase for it in Account code, but it's handled well by the backend.
                // However, if the already authenticated user is different from the one we want to authenticate,
                // it indicates issue. It will be rejected on the backend side and should cause an invalidation of
                // the stored session on the client side.
                guard credential.isForUnauthenticatedSession || credential.userName == username else {
                    PMLog.error("""
                                According to the best of Account iOS team knowledge, POST /auth call must not happen in context of auth session of different user.
                                Calling it in this scenario is like logging another user inside the session of already logged in user.
                                This is programmer's error and must be investigated.
                                """, sendToExternal: true)
                    // we invalidate both authenticated and unauthenticated session
                    // if POST /auth is called within the context of auth session,
                    // because we want to clear the session completely and start from the clean slate
                    PMLog.signpost("Authenticated session invalidated (BAD) in \(#function)", level: .info)
                    service.authDelegate?.onAuthenticatedSessionInvalidated(sessionUID: credential.sessionID)
                    service.authDelegate?.onUnauthenticatedSessionInvalidated(sessionUID: credential.sessionID)
                    service.acquireSessionIfNeeded { _ in /* result ignored by design, we don't use it */ }
                    complete(.failure(.init(
                        httpCode: nil, responseCode: nil, userFacingMessage: "Internal error. Please try again.", underlyingError: nil
                    )))
                    return
                }
            case .notFound, .wrongConfigurationNoDelegate:
                break
            }
            service.perform(request: route, decodableCompletion: { _, result in complete(result) })
        }
    }
}
