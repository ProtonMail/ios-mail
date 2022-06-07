//
//  Login.swift
//  ProtonCore-Login - Created on 05/11/2020.
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

public enum LoginError: Error, CustomStringConvertible {
    case invalidSecondPassword
    case invalidCredentials(message: String)
    case invalid2FACode(message: String)
    case invalidAccessToken(message: String)
    case generic(message: String, code: Int, originalError: Error)
    case invalidState
    case missingKeys
    case needsFirstTimePasswordChange
    case emailAddressAlreadyUsed
}

extension LoginError: Equatable {
    public static func == (lhs: LoginError, rhs: LoginError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidSecondPassword, .invalidSecondPassword),
            (.invalidState, .invalidState),
            (.missingKeys, .missingKeys),
            (.needsFirstTimePasswordChange, .needsFirstTimePasswordChange),
            (.emailAddressAlreadyUsed, .emailAddressAlreadyUsed):
            return true
        case (.invalidCredentials(let lv), .invalidCredentials(let rv)),
            (.invalid2FACode(let lv), .invalid2FACode(let rv)),
            (.invalidAccessToken(let lv), .invalidAccessToken(let rv)):
            return lv == rv
        case let (.generic(lmessage, lcode, _), .generic(rmessage, rcode, _)):
            return lmessage == rmessage && lcode == rcode
        default:
            return false
        }
    }
}

public extension LoginError {
    var userFacingMessageInLogin: String {
        switch self {
        case .invalidCredentials(let message),
             .invalid2FACode(let message),
             .invalidAccessToken(let message),
             .generic(let message, _, _):
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
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum SignupError: Error {
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
    case generic(message: String, code: Int, originalError: Error)
}

extension SignupError: Equatable {
    public static func == (lhs: SignupError, rhs: SignupError) -> Bool {
        switch (lhs, rhs) {
        case (.emailAddressAlreadyUsed, .emailAddressAlreadyUsed),
            (.validationTokenRequest, .validationTokenRequest),
            (.validationToken, .validationToken),
            (.randomBits, .randomBits),
            (.cantHashPassword, .cantHashPassword),
            (.passwordEmpty, .passwordEmpty),
            (.passwordNotEqual, .passwordNotEqual),
            (.passwordShouldHaveAtLeastEightCharacters, .passwordShouldHaveAtLeastEightCharacters):
            return true
        case (.invalidVerificationCode(let lv), .invalidVerificationCode(let rv)),
            (.generateVerifier(let lv), .generateVerifier(let rv)):
            return lv == rv
        case let (.generic(lmessage, lcode, _), .generic(rmessage, rcode, _)):
            return lmessage == rmessage && lcode == rcode
        default:
            return false
        }
    }
}

public extension SignupError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _, _),
             .generateVerifier(let message),
             .invalidVerificationCode(let message):
            return message
        default:
            return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum AvailabilityError: Error {
    case notAvailable(message: String)
    case generic(message: String, code: Int, originalError: Error)
}

public extension AvailabilityError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _, _), .notAvailable(let message): return message
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum SetUsernameError: Error {
    case alreadySet(message: String)
    case generic(message: String, code: Int, originalError: Error)
}

public extension SetUsernameError {
    var userFacingMessageInLogin: String {
        switch self {
        case .alreadySet(let message), .generic(let message, _, _): return message
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum CreateAddressError: Error {
    case alreadyHaveInternalOrCustomDomainAddress(Address)
    case cannotCreateInternalAddress(alreadyExistingAddress: Address?)
    case generic(message: String, code: Int, originalError: Error)
}

public extension CreateAddressError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _, _): return message
        default: return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public enum CreateAddressKeysError: Error {
    case alreadySet
    case generic(message: String, code: Int, originalError: Error)
}

public extension CreateAddressKeysError {
    var userFacingMessageInLogin: String {
        switch self {
        case .generic(let message, _, _): return message
        case .alreadySet: return localizedDescription
        }
    }
    
    var codeInLogin: Int {
        switch self {
        case .generic(_, let code, _): return code
        default: return bestShotAtReasonableErrorCode
        }
    }
}

public protocol Login {
    var currentlyChosenSignUpDomain: String { get set }
    var allSignUpDomains: [String] { get }
    func updateAllAvailableDomains(type: AvailableDomainsType, result: @escaping ([String]?) -> Void)

    func login(username: String, password: String, challenge: [String: Any]?, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func finishLoginFlow(mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void)

    func checkAvailabilityForUsernameAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    func checkAvailabilityForInternalAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    func checkAvailabilityForExternalAccount(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void)
    
    func setUsername(username: String, completion: @escaping (Result<(), SetUsernameError>) -> Void)

    func createAccountKeysIfNeeded(user: User, addresses: [Address]?, mailboxPassword: String?, completion: @escaping (Result<User, LoginError>) -> Void)
    func createAddress(completion: @escaping (Result<Address, CreateAddressError>) -> Void)
    func createAddressKeys(user: User, address: Address, mailboxPassword: String, completion: @escaping (Result<Key, CreateAddressKeysError>) -> Void)
    
    func refreshCredentials(completion: @escaping (Result<Credential, LoginError>) -> Void)
    func refreshUserInfo(completion: @escaping (Result<User, LoginError>) -> Void)

    var minimumAccountType: AccountType { get }
    func updateAccountType(accountType: AccountType)
    var startGeneratingAddress: (() -> Void)? { get set }
    var startGeneratingKeys: (() -> Void)? { get set }
}

public extension Login {

    @available(*, deprecated, renamed: "currentlyChosenSignUpDomain")
    var signUpDomain: String { currentlyChosenSignUpDomain }
    
    @available(*, deprecated, message: "this will be removed. use the function with challenge")
    func login(username: String, password: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        login(username: username, password: password, challenge: nil, completion: completion)
    }
    
    @available(*, deprecated, message: "Please switch to the updateAllAvailableDomains variant that returns all domains instead of just a first one")
    func updateAvailableDomain(type: AvailableDomainsType, result: @escaping (String?) -> Void) {
        updateAllAvailableDomains(type: type) { result($0?.first) }
    }
    
    @available(*, deprecated, renamed: "checkAvailabilityForUsernameAccount")
    func checkAvailability(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        checkAvailabilityForUsernameAccount(username: username, completion: completion)
    }
    
    @available(*, deprecated, renamed: "checkAvailabilityForInternalAccount")
    func checkAvailabilityWithinDomain(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        checkAvailabilityForInternalAccount(username: username, completion: completion)
    }
    
    @available(*, deprecated, renamed: "checkAvailabilityForExternalAccount")
    func checkAvailabilityExternal(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        checkAvailabilityForExternalAccount(email: email, completion: completion)
    }
}
