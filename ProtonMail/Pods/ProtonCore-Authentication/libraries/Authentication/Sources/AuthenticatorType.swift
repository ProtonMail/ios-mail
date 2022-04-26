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
import ProtonCore_APIClient
import ProtonCore_DataModel
import ProtonCore_Networking
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

public protocol AuthenticatorInterface {

    func authenticate(username: String, password: String, srpAuth: SrpAuth?, completion: @escaping Authenticator.Completion)

    func confirm2FA(_ twoFactorCode: String, context: TwoFactorContext, completion: @escaping Authenticator.Completion)

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
                       siganture: String?,
                       completion: @escaping (Result<Address, AuthErrors>) -> Void)

    func getUserInfo(_ credential: Credential?, completion: @escaping (Result<User, AuthErrors>) -> Void)

    func getAddresses(_ credential: Credential?, completion: @escaping (Result<[Address], AuthErrors>) -> Void)

    func getKeySalts(_ credential: Credential?, completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void)
    
    func forkSession(_ credential: Credential,
                     completion: @escaping (Result<AuthService.ForkSessionResponse, AuthErrors>) -> Void)

    func closeSession(_ credential: Credential,
                      completion: @escaping (Result<AuthService.EndSessionResponse, AuthErrors>) -> Void)

    func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, AuthErrors>) -> Void)
}

// Workaround for the lack of default parameters in protocols

public extension AuthenticatorInterface {
    @available(*, deprecated, renamed: "checkAvailableUsernameWithoutSpecifyingDomain")
    func checkAvailable(_ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        checkAvailableUsernameWithoutSpecifyingDomain(username, completion: completion)
    }
    
    func authenticate(username: String, password: String, completion: @escaping Authenticator.Completion) {
        authenticate(username: username, password: password, srpAuth: nil, completion: completion)
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
        createAddress(nil, domain: domain, displayName: nil, siganture: nil, completion: completion)
    }
}
