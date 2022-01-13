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
import ProtonCore_CoreTranslation

public struct CreateAddressData {
    public let email: String
    public let credential: AuthCredential
    public let user: User
    public let mailboxPassword: String
    
    public init(email: String, credential: AuthCredential, user: User, mailboxPassword: String) {
        self.email = email
        self.credential = credential
        self.user = user
        self.mailboxPassword = mailboxPassword
    }

    public func withUpdatedUser(_ user: User) -> CreateAddressData {
        CreateAddressData(email: email, credential: credential, user: user, mailboxPassword: mailboxPassword)
    }
}

public enum LoginStatus {
    case finished(LoginData)
    case ask2FA
    case askSecondPassword
    case chooseInternalUsernameAndCreateInternalAddress(CreateAddressData)
}

public enum LoginError: Error, Equatable, CustomStringConvertible {
    case invalidSecondPassword
    case invalidCredentials(message: String)
    case invalid2FACode(message: String)
    case invalidAccessToken(message: String)
    case generic(message: String, code: Int)
    case invalidState
    case missingKeys
    case needsFirstTimePasswordChange
    case emailAddressAlreadyUsed
}

public extension LoginError {
    var userFacingMessageInLogin: String {
        switch self {
        case .invalidCredentials(let message),
             .invalid2FACode(let message),
             .invalidAccessToken(let message),
             .generic(let message, _):
            return message
        case .invalidState,
             .invalidSecondPassword,
             .missingKeys,
             .needsFirstTimePasswordChange,
             .emailAddressAlreadyUsed:
            return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum SignupError: Error, Equatable {
    case emailAddressAlreadyUsed
    case invalidVerificationCode(message: String)
    case validationTokenRequest
    case validationToken
    case randomBits
    case generateVerifier(underlyingErrorDescription: String)
    case cantHashPassword
    case passwordEmpty
    case passwordNotEqual
    case passwordShouldHaveAtLeastEightCharacters
    case generic(message: String, code: Int)
}

public extension SignupError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _),
             .generateVerifier(let message),
             .invalidVerificationCode(let message):
            return message
        default:
            return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum AvailabilityError: Error {
    case notAvailable(message: String)
    case generic(message: String, code: Int)
}

public extension AvailabilityError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _), .notAvailable(let message): return message
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum SetUsernameError: Error {
    case alreadySet(message: String)
    case generic(message: String, code: Int)
}

public extension SetUsernameError {
    var userFacingMessageInLogin: String {
        switch self {
        case .alreadySet(let message), .generic(let message, _): return message
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum CreateAddressError: Error {
    case alreadyHaveInternalOrCustomDomainAddress(Address)
    case cannotCreateInternalAddress(alreadyExistingAddress: Address?)
    case generic(message: String, code: Int)
}

public extension CreateAddressError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _): return message
        default: return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum CreateAddressKeysError: Error {
    case alreadySet
    case generic(message: String, code: Int)
}

public extension CreateAddressKeysError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _): return message
        case .alreadySet: return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public protocol Login {
    var signUpDomain: String { get }

    func login(username: String, password: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func finishLoginFlow(mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void)

    func checkAvailability(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    func checkAvailabilityExternal(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    func setUsername(username: String, completion: @escaping (Result<(), SetUsernameError>) -> Void)

    func createAccountKeysIfNeeded(user: User, addresses: [Address]?, mailboxPassword: String?, completion: @escaping (Result<User, LoginError>) -> Void)
    func createAddress(completion: @escaping (Result<Address, CreateAddressError>) -> Void)
    func createAddressKeys(user: User, address: Address, mailboxPassword: String, completion: @escaping (Result<Key, CreateAddressKeysError>) -> Void)
    
    func refreshCredentials(completion: @escaping (Result<Credential, LoginError>) -> Void)
    func refreshUserInfo(completion: @escaping (Result<User, LoginError>) -> Void)

    var minimumAccountType: AccountType { get }
    func updateAccountType(accountType: AccountType)
    func updateAvailableDomain(type: AvailableDomainsType, result: @escaping (String?) -> Void)
    var startGeneratingAddress: (() -> Void)? { get set }
    var startGeneratingKeys: (() -> Void)? { get set }
}
