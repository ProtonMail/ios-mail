//
//  Authenticator.swift
//  ProtonCore-Authentication - Created on 19/02/2020.
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
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreNetworking
import ProtonCoreServices

public class Authenticator: NSObject, AuthenticatorInterface {

    public typealias Errors = AuthErrors
    public typealias Completion = (Result<Status, AuthErrors>) -> Void

    public enum Status {
        case askTOTP(TOTPContext)
        case askFIDO2(FIDO2Context)
        case askAny2FA(TOTPContext, FIDO2Context)
        case newCredential(Credential, PasswordMode)
        case updatedCredential(Credential)
        case ssoChallenge(SSOChallengeResponse)
    }

    public var apiService: APIService!
    public init(api: APIService) {
        self.apiService = api
        super.init()
    }

    // we do not want this to be ever used
    override private init() { }

    private let srpBuilder = SRPBuilder()

    /// login with SSO
    public func authenticate(idpEmail: String,
                             responseToken: SSOResponseToken,
                             completion: @escaping Completion) {
        // 1. auth info request
        let authClient = AuthService(api: self.apiService)
        authClient.ssoAuthentication(ssoResponseToken: responseToken) { [weak self] response in
            switch response {
            case .success(let authResponse):
                let credential = Credential(res: authResponse, userName: idpEmail, userID: authResponse.userID)
                self?.apiService.setSessionUID(uid: credential.UID)
                completion(.success(.newCredential(credential, authResponse.passwordMode)))
            case .failure(let error):
                completion(.failure(.networkingError(error)))
            }
        }
    }

    /// Clear login, when previously unauthenticated
    public func authenticate(username: String,
                             password: String,
                             challenge: ChallengeProperties?,
                             intent: Intent? = nil,
                             srpAuth: SrpAuth? = nil,
                             completion: @escaping Completion) {
        // 1. auth info request
        let authClient = AuthService(api: self.apiService)
        authClient.info(username: username, intent: intent) { [weak self] response in
            switch response {
            case .success(let eitherResponse):
                switch eitherResponse {
                case .left(let authInfoResponse):
                    self?.handleAuthInfoResponse(username: username,
                                                 password: password,
                                                 challenge: challenge,
                                                 response: authInfoResponse,
                                                 authClient: authClient,
                                                 srpAuth: srpAuth,
                                                 completion: completion)
                case .right(let ssoResponse):
                    completion(.success(.ssoChallenge(ssoResponse)))
                }
            case .failure(let error):
                completion(.failure(.networkingError(error)))
            }
        }
    }

    private func handleAuthInfoResponse(username: String,
                                        password: String,
                                        challenge: ChallengeProperties?,
                                        response: AuthInfoResponse,
                                        authClient: AuthService,
                                        srpAuth: SrpAuth? = nil,
                                        completion: @escaping Completion) {
        if let responseError = response.error {
            completion(.failure(.from(responseError)))
            return
        }

        // 2. build SRP things
        do {
            let srpClientInfo = try self.srpBuilder.buildSRP(
                username: username,
                password: password,
                authInfo: AuthInfoResponse(
                    modulus: response.modulus,
                    serverEphemeral: response.serverEphemeral,
                    version: response.version,
                    salt: response.salt,
                    srpSession: response.srpSession
                ),
                srpAuth: srpAuth
            )

            switch srpClientInfo {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let srpClientInfo):
                // 3. auth request
                authClient.auth(username: username, ephemeral: srpClientInfo.clientEphemeral, proof: srpClientInfo.clientProof, srpSession: response.srpSession, challenge: challenge) { (result) in
                    switch result {
                    case .failure(let responseError):
                        completion(.failure(.from(responseError)))
                    case .success(let authResponse):
                        guard let serverProof = authResponse.serverProof, srpClientInfo.expectedServerProof == Data(base64Encoded: serverProof) else {
                            return completion(.failure(Errors.wrongServerProof))
                        }
                        // are we done yet or need 2FA?
                        guard authResponse._2FA.enabled.rawValue <= 3 else {
                            return completion(.failure(Errors.notImplementedYet("Unknown 2FA method required")))
                        }
                        let areFidoKeysEnabled = FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.fidoKeys,
                                                                                         reloadValue: true)
                        let credential = Credential(res: authResponse, userName: username, userID: authResponse.userID)
                        self.apiService.setSessionUID(uid: credential.UID)
                        var totpContext: TOTPContext?
                        var fido2Context: FIDO2Context?
                        if authResponse._2FA.enabled.contains(.totp) {
                            totpContext = .init(credential: credential, passwordMode: authResponse.passwordMode)
                        }
                        if authResponse._2FA.enabled.contains(.webAuthn) && areFidoKeysEnabled {
                            guard let fido2 = authResponse._2FA.FIDO2,
                                  let authenticationOptions = fido2.authenticationOptions else {
                                completion(.failure(Errors.emptyAuthInfoResponse))
                                return
                            }
                            fido2Context = .init(authenticationOptions: authenticationOptions,
                                                 credential: credential,
                                                 passwordMode: authResponse.passwordMode)
                        }

                        switch authResponse._2FA.enabled {
                        case .off:
                            completion(.success(.newCredential(credential, authResponse.passwordMode)))
                        case .both where !areFidoKeysEnabled:
                                if let totpContext {
                                    return completion(.success(.askTOTP(totpContext)))
                                } else {
                                    return completion(.failure(Errors.notImplementedYet("WebAuthn not implemented yet")))
                                }
                        case .both where areFidoKeysEnabled:
                            if let totpContext, let fido2Context {
                                return completion(.success(.askAny2FA(totpContext, fido2Context)))
                            } else {
                                return completion(.failure(.insufficientFIDO2Details))
                            }
                        case .totp:
                            if let totpContext {
                                return completion(.success(.askTOTP(totpContext)))
                            } else {
                                return completion(.failure(.emptyAuthInfoResponse))
                            }
                        case .webAuthn:
                            guard areFidoKeysEnabled else {
                                completion(.failure(Errors.notImplementedYet("WebAuthn not implemented yet")))
                                return
                            }
                            if let fido2Context { 
                                completion(.success(.askFIDO2(fido2Context)))
                            } else {
                                completion(.failure(.insufficientFIDO2Details))
                            }
                        default:
                            // should already be controlled in previous check
                            completion(.failure(Errors.notImplementedYet("Unknown 2FA method required")))
                        }
                    }
                }
            }
        } catch let parsingError {
            return completion(.failure(.parsingError(parsingError)))
        }
    }
    /// Continue clear login flow with 2FA code
    public func confirm2FA(_ twoFactorCode: String,
                           context: TOTPContext, completion: @escaping Completion) {
        var route = AuthService.TwoFAEndpoint(code: twoFactorCode)
        route.auth = AuthCredential(context.credential)
        self.apiService.perform(request: route) { (_, result: Result<AuthService.TwoFAResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.from(responseError)))
            case .success(let response):
                var credential = context.credential
                credential.scopes = response.scopes
                completion(.success(.newCredential(credential, context.passwordMode)))
            }
        }
    }

    /// Send FIDO2 key signature
    public func sendFIDO2Signature(_ signature: Fido2Signature, context: FIDO2Context, completion: @escaping Completion) {
        var route = AuthService.TwoFAEndpoint(signature: signature, authenticationOptions: context.authenticationOptions)
        route.auth = AuthCredential(context.credential)
        self.apiService.perform(request: route) { (_, result: Result<AuthService.TwoFAResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.from(responseError)))
            case .success(let response):
                var credential = context.credential
                credential.scopes = response.scopes
                completion(.success(.newCredential(credential, context.passwordMode)))
            }
        }
    }

    // Refresh expired access token using refresh token
    public func refreshCredential(_ oldCredential: Credential, completion: @escaping Completion) {
        self.apiService.refreshCredential(oldCredential) { (result: Result<Credential, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.from(responseError)))
            case .success(let credential):
                completion(.success(.updatedCredential(credential)))
            }
        }
    }

    public func checkAvailableUsernameWithoutSpecifyingDomain(
        _ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void
    ) {
        let route = AuthService.UserAvailableWithoutSpecifyingDomainEndpoint(username: username)

        self.apiService.perform(request: route) { (_, result: Result<AuthService.UserAvailableResponse, ResponseError>) in
            completion(result.map { _ in () }.mapError { AuthErrors.from($0) })
        }
    }

    public func checkAvailableUsernameWithinDomain(
        _ username: String, domain: String, completion: @escaping (Result<(), AuthErrors>) -> Void
    ) {
        let route = AuthService.UserAvailableWithinDomainEndpoint(username: username, domain: domain)
        self.apiService.perform(request: route) { (_, result: Result<AuthService.UserAvailableResponse, ResponseError>) in
            completion(result.map { _ in () }.mapError { AuthErrors.from($0) })
        }
    }

    public func checkAvailableExternal(_ email: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.UserAvailableExternalEndpoint(email: email)

        self.apiService.perform(request: route) { (_, result: Result<AuthService.UserAvailableExternalResponse, ResponseError>) in
            completion(result.map { _ in () }.mapError { AuthErrors.from($0) })
        }
    }

    public func setUsername(_ credential: Credential? = nil, username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        var route = AuthService.SetUsernameEndpoint(username: username)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route) { (_, result: Result<AuthService.SetUsernameResponse, ResponseError>) in
            completion(result.map { _ in () }.mapError { AuthErrors.from($0) })
        }
    }

    public func createAddress(_ credential: Credential? = nil,
                              domain: String,
                              displayName: String? = nil,
                              signature: String? = nil,
                              completion: @escaping (Result<Address, AuthErrors>) -> Void) {
        var route = AuthService.CreateAddressEndpoint(domain: domain, displayName: displayName, signature: signature)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route) { (_, result: Result<AuthService.CreateAddressEndpointResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.from(responseError)))
            case let .success(data):
                completion(.success(data.address))
            }
        }
    }

    public func createUser(userParameters: UserParameters, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.CreateUserEndpoint(userParameters: userParameters)
        self.apiService.perform(request: route, response: Response()) { (_, response) in
            if let responseError = response.error {
                completion(.failure(.from(responseError)))
            } else {
                completion(.success(()))
            }
        }
    }

    public func createExternalUser(externalUserParameters: ExternalUserParameters, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.CreateExternalUserEndpoint(externalUserParameters: externalUserParameters)
        self.apiService.perform(request: route, response: Response()) { (_, response) in
            if let responseError = response.error {
                completion(.failure(.from(responseError)))
            } else {
                completion(.success(()))
            }
        }
    }

    public func getUserInfo(_ credential: Credential? = nil, completion: @escaping (Result<User, AuthErrors>) -> Void) {
        var route = AuthService.UserInfoEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapValueAndError(completion) { (response: AuthService.UserResponse) in
            response.user
        })
    }

    public func getAddresses(_ credential: Credential? = nil, completion: @escaping (Result<[Address], AuthErrors>) -> Void) {
        var route = AuthService.AddressEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapValueAndError(completion) { (response: AuthService.AddressesResponse) in
            response.addresses
        })
    }

    public func getKeySalts(_ credential: Credential? = nil, completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void) {
        var route = AuthService.KeySaltsEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapValueAndError(completion) { (response: AuthService.KeySaltsResponse) in
            response.keySalts
        })
    }

    public func forkSession(_ credential: Credential? = nil,
                            useCase: AuthService.ForkSessionUseCase,
                            completion: @escaping (Result<AuthService.ForkSessionResponse, AuthErrors>) -> Void) {
        var route = AuthService.ForkSessionEndpoint(useCase: useCase)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapError(completion))
    }

    private func obtainChildSession(_ credential: Credential? = nil,
                                    selector: String,
                                    completion: @escaping (Result<AuthService.ChildSessionResponse, AuthErrors>) -> Void) {
        var route = AuthService.ChildSessionRequest(selector: selector)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapError(completion))
    }

    public func performForkingAndObtainChildSession(_ credential: Credential,
                                                    useCase: AuthService.ForkSessionUseCase,
                                                    completion: @escaping (Result<Credential, AuthErrors>) -> Void) {
        forkSession(credential, useCase: useCase) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                self.obtainChildSession(credential, selector: response.selector) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let childSessionResponse):
                        // According to the (documentation)[https://confluence.protontech.ch/pages/viewpage.action?pageId=11865449],
                        // the credentials obtained from forking session must be refreshed to be usable
                        let childSessionPartialCredentials = Credential(UID: childSessionResponse.UID,
                                                                        accessToken: childSessionResponse.accessToken,
                                                                        refreshToken: childSessionResponse.refreshToken,
                                                                        userName: credential.userName,
                                                                        userID: childSessionResponse.userID,
                                                                        scopes: childSessionResponse.scopes)
                        self.apiService.refreshCredential(childSessionPartialCredentials) { result in
                            switch result {
                            case .success(let credential):
                                completion(.success(credential))
                            case .failure(let error):
                                completion(.failure(AuthErrors.from(error)))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func closeSession(_ credential: Credential? = nil, completion: @escaping (Result<AuthService.EndSessionResponse, AuthErrors>) -> Void) {
        var route = AuthService.EndSessionEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.perform(request: route, decodableCompletion: mapError(completion))
    }

    public func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, AuthErrors>) -> Void) {
        let route = AuthService.ModulusEndpoint()
        self.apiService.perform(request: route, decodableCompletion: mapError(completion))
    }

    private func mapValueAndError<T, S>(_ completion: @escaping (Result<T, AuthErrors>) -> Void,
                                        _ f: @escaping (S) -> T) -> (URLSessionDataTask?, Result<S, ResponseError>) -> Void {
        return { (_, result: Result<S, ResponseError>) -> Void in
            completion(result.map(f).mapError {
                $0.isApiIsBlockedError ? AuthErrors.apiMightBeBlocked(message: $0.localizedDescription, originalError: $0) : .networkingError($0)
            })
        }
    }

    private func mapError<T>(_ completion: @escaping (Result<T, AuthErrors>) -> Void) -> (URLSessionDataTask?, Result<T, ResponseError>) -> Void {
        return { (_, result: Result<T, ResponseError>) in
            completion(result.mapError {
                $0.isApiIsBlockedError ? AuthErrors.apiMightBeBlocked(message: $0.localizedDescription, originalError: $0) : .networkingError($0)
            })
        }
    }
}

@available(*, deprecated, message: "Use AuthDelegateHelper instead, it provides more robust API")
public enum RefreshAccessToken {

    public static func callAsFunction(
        credential: Credential, using api: APIService, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        refresh(credential: credential, using: Authenticator(api: api), completion: completion)
    }

    public static func callAsFunction(
        credential: Credential, using authenticator: Authenticator, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        refresh(credential: credential, using: authenticator, completion: completion)
    }

    private static func refresh(
        credential: Credential, using authenticator: Authenticator, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        authenticator.apiService.refreshCredential(credential, completion: completion)
    }

}
