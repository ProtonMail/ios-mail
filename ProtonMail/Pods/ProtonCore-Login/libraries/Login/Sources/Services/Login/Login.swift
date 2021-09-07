//
//  Login.swift
//  ProtonCore-Login - Created on 05/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import ProtonCore_Networking
import ProtonCore_DataModel

struct CreateAddressData {
    let email: String
    let credential: AuthCredential
    let user: User
    let mailboxPassword: String

    func withUpdatedUser(_ user: User) -> CreateAddressData {
        CreateAddressData(email: email, credential: credential, user: user, mailboxPassword: mailboxPassword)
    }
}

enum LoginStatus {
    case finished(LoginData)
    case ask2FA
    case askSecondPassword
    case chooseInternalUsernameAndCreateInternalAddress(CreateAddressData)
}

enum LoginError: Error, Equatable {
    case invalidSecondPassword
    case invalidCredentials(message: String)
    case invalid2FACode(message: String)
    case invalidAccessToken(message: String)
    case generic(message: String)
    case invalidState
    case missingKeys
    case needsFirstTimePasswordChange
    case emailAddressAlreadyUsed
}

extension LoginError {
    var messageForTheUser: String {
        return localizedDescription
    }
}

enum SignupError: Error, Equatable {
    case deviceTokenError
    case deviceTokenUnsuported
    case emailAddressAlreadyUsed
    case invalidVerificationCode(message: String)
    case validationTokenRequest
    case validationToken
    case randomBits
    case cantHashPassword
    case passwordEmpty
    case passwordNotEqual
    case passwordShouldHaveAtLeastEightCharacters
    case generic(message: String)
}

extension SignupError {
    var messageForTheUser: String {
        return localizedDescription
    }
}

enum AvailabilityError: Error {
    case notAvailable(message: String)
    case generic(message: String)
}

extension AvailabilityError {
    var messageForTheUser: String {
        return localizedDescription
    }
}

enum SetUsernameError: Error {
    case alreadySet(message: String)
    case generic(message: String)
}

enum CreateAddressError: Error {
    case alreadyHaveInternalOrCustomDomainAddress(Address)
    case cannotCreateInternalAddress(alreadyExistingAddress: Address?)
    case generic(message: String)
}

enum CreateAddressKeysError: Error {
    case alreadySet
    case generic(message: String)
}

extension CreateAddressKeysError {
    var messageForTheUser: String {
        return localizedDescription
    }
}

protocol Login {
    var signUpDomain: String { get }

    func login(username: String, password: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func finishLoginFlow(mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void)

    func checkAvailability(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    func setUsername(username: String, completion: @escaping (Result<(), SetUsernameError>) -> Void)

    func createAccountKeysIfNeeded(user: User, addresses: [Address]?, mailboxPassword: String?, completion: @escaping (Result<User, LoginError>) -> Void)
    func createAddress(completion: @escaping (Result<Address, CreateAddressError>) -> Void)
    func createAddressKeys(user: User, address: Address, mailboxPassword: String, completion: @escaping (Result<Key, CreateAddressKeysError>) -> Void)

    var minimumAccountType: AccountType { get }
    func updateAccountType(accountType: AccountType)
    func updateAvailableDomain(type: AvailableDomainsType, result: @escaping (String?) -> Void)
}
