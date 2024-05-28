//
//  AuthenticatorType.swift
//  ProtonCore-Authentication - Created on 20/05/2021.
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
import ProtonCoreNetworking
import ProtonCoreServices

/// Handles interactions with the Authentication routes.
public protocol AuthenticatorInterface {
    func authenticate(idpEmail: String, responseToken: SSOResponseToken, completion: @escaping Authenticator.Completion)

    func authenticate(username: String, password: String, challenge: ChallengeProperties?, intent: Intent?, srpAuth: SrpAuth?, completion: @escaping Authenticator.Completion)

    /// Sends TOTP code to complete authentication after logging in with a TOTP enabled account
    func confirm2FA(_ twoFactorCode: String, context: TOTPContext, completion: @escaping Authenticator.Completion)

    /// Sends FIDO2 signed challenge to complete authentication after logging in with a FIDO2 enabled account
    /// - Parameters:
    ///   - signature: Signed challenge
    ///   - context: Contains details pertaining to the original auth request and the challenge
    ///   - completion: Completion closure which will receive the result of the request
    func sendFIDO2Signature(_ signature: Fido2Signature, context: FIDO2Context, completion: @escaping Authenticator.Completion)

    func refreshCredential(_ oldCredential: Credential, completion: @escaping Authenticator.Completion)

    func checkAvailableUsernameWithoutSpecifyingDomain(_ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func checkAvailableUsernameWithinDomain(_ username: String, domain: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func checkAvailableExternal(_ email: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func setUsername(username: String, completion: @escaping (Result<(), AuthErrors>) -> Void)

    func setUsername(_ credential: Credential?,
                     username: String,
                     completion: @escaping (Result<(), AuthErrors>) -> Void)

    func createAddress(_ credential: Credential?,
                       domain: String,
                       displayName: String?,
                       signature: String?,
                       completion: @escaping (Result<Address, AuthErrors>) -> Void)

    func getUserInfo(_ credential: Credential?, completion: @escaping (Result<User, AuthErrors>) -> Void)

    func getAddresses(_ credential: Credential?, completion: @escaping (Result<[Address], AuthErrors>) -> Void)

    func getKeySalts(_ credential: Credential?, completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void)

    /// Forks the session to get a selector which can be later used to obtain the child session.
    ///
    /// - Parameters:
    ///   - credential: The parent session credentials. If left empty, they will be fetched from the AuthDelegate assigned to
    ///                 the APIService used by the Authenticator.
    ///   - useCase: Who are we forking the session for. It must be provided from the callee side, because
    ///              the forking endpoint needs to know who we fork the session for. Depending on what we pass,
    ///              the child session will have different scopes and abilities.
    ///   - completion: The completion block. If successful, the selector is available. If not, the error.
    func forkSession(_ credential: Credential?,
                     useCase: AuthService.ForkSessionUseCase,
                     completion: @escaping (Result<AuthService.ForkSessionResponse, AuthErrors>) -> Void)

    /// Performs the whole child session flow, which consists of three network calls:
    /// 1. Forks the session to get the selector which can be later used to obtain the child session.
    /// 2. Exchanges the selector for the inactive child session credentials.
    /// 3. Refreshes the inactive child session credentials to have the active ones.
    ///
    /// The flow is documented at https://confluence.protontech.ch/pages/viewpage.action?pageId=11865449
    ///
    /// - Parameters:
    ///   - credential: The parent session credentials. If left empty, they will be fetched from the AuthDelegate assigned to
    ///                 the APIService used by the Authenticator.
    ///   - useCase: Who are we forking the session for. It must be provided from the callee side, because
    ///              the forking endpoint needs to know who we fork the session for. Depending on what we pass,
    ///              the child session will have different scopes and abilities.
    ///   - completion: The completion block. If successful, the child session credentials are returned, active and ready to be used.
    ///                 If not, the error.
    func performForkingAndObtainChildSession(_ credential: Credential,
                                             useCase: AuthService.ForkSessionUseCase,
                                             completion: @escaping (Result<Credential, AuthErrors>) -> Void)

    func closeSession(_ credential: Credential?,
                      completion: @escaping (Result<AuthService.EndSessionResponse, AuthErrors>) -> Void)

    func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, AuthErrors>) -> Void)
}

// Workaround for the lack of default parameters in protocols

public extension AuthenticatorInterface {

    @available(*, deprecated, message: "Please use the function with challenge")
    func authenticate(username: String, password: String, srpAuth: SrpAuth?, completion: @escaping Authenticator.Completion) {
        authenticate(username: username, password: password, challenge: nil, intent: nil, srpAuth: srpAuth, completion: completion)
    }

    @available(*, deprecated, renamed: "checkAvailableUsernameWithoutSpecifyingDomain")
    func checkAvailable(_ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        checkAvailableUsernameWithoutSpecifyingDomain(username, completion: completion)
    }

    func setUsername(username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        setUsername(nil, username: username, completion: completion)
    }
    func getKeySalts(completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void) {
        getKeySalts(nil, completion: completion)
    }
    func getUserInfo(completion: @escaping (Result<User, AuthErrors>) -> Void) {
        getUserInfo(nil, completion: completion)
    }
    func getAddresses(completion: @escaping (Result<[Address], AuthErrors>) -> Void) {
        getAddresses(nil, completion: completion)
    }
    func createAddress(domain: String, completion: @escaping (Result<Address, AuthErrors>) -> Void) {
        createAddress(nil, domain: domain, displayName: nil, signature: nil, completion: completion)
    }
}
