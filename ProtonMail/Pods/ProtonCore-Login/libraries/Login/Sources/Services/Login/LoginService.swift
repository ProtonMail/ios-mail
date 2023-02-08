//
//  SignInService.swift
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
import ProtonCore_APIClient
import ProtonCore_Authentication
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

public final class LoginService: Login {

    public typealias AuthenticationManager = AuthenticatorInterface & AuthenticatorKeyGenerationInterface

    // MARK: - Properties

    let apiService: APIService
    var sessionId: String { apiService.sessionUID }
    let clientApp: ClientApp
    let manager: AuthenticationManager
    var context: TwoFactorContext?
    var mailboxPassword: String?
    public private(set) var minimumAccountType: AccountType
    var username: String?

    var defaultSignUpDomain = "protonmail.com"
    var updatedSignUpDomains: [String]?
    var chosenSignUpDomain: String?
    public var currentlyChosenSignUpDomain: String {
        get {
            chosenSignUpDomain ?? updatedSignUpDomains?.first ?? defaultSignUpDomain
        }
        set {
            if allSignUpDomains.contains(newValue) {
                chosenSignUpDomain = newValue
            }
        }
    }
    public var allSignUpDomains: [String] {
        return updatedSignUpDomains ?? [defaultSignUpDomain]
    }
    public var startGeneratingAddress: (() -> Void)?
    public var startGeneratingKeys: (() -> Void)?

    public init(api: APIService, clientApp: ClientApp, minimumAccountType: AccountType, authenticator: AuthenticationManager? = nil) {
        self.apiService = api
        self.minimumAccountType = minimumAccountType
        self.clientApp = clientApp
        manager = authenticator ?? Authenticator(api: api)
    }

    // MARK: - Configuration

    public func updateAccountType(accountType: AccountType) {
        minimumAccountType = accountType
    }

    public func updateAllAvailableDomains(type: AvailableDomainsType, result: @escaping ([String]?) -> Void) {
        updatedSignUpDomains = nil
        availableDomains(type: type) { res in
            switch res {
            case .success(let domains):
                self.updatedSignUpDomains = domains
                result(domains)
            case .failure:
                self.updatedSignUpDomains = nil
                result(nil)
            }
        }
    }

    private func availableDomains(type: AvailableDomainsType, completion: @escaping (Result<([String]), LoginError>) -> Void) {
        let route = AvailableDomainsRequest(type: type)

        apiService.perform(request: route) { (_, result: Result<AvailableDomainResponse, ResponseError>) in
            switch result {
            case .failure(let error):
                completion(.failure(LoginError.generic(message: error.networkResponseMessageForTheUser,
                                                       code: error.bestShotAtReasonableErrorCode,
                                                       originalError: error)))
            case .success(let response):
                completion(.success(response.domains))
            }
        }
    }
    
    public func refreshCredentials(completion: @escaping (Result<Credential, LoginError>) -> Void) {
        withAuthDelegateAvailable(completion) { authManager in
            guard let old = authManager.credential(sessionUID: self.sessionId) else {
                completion(.failure(.invalidState))
                return
            }
            manager.refreshCredential(old) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error.asLoginError()))
                case .success(.ask2FA):
                    completion(.failure(.invalidState))
                case .success(.newCredential(let credential, _)), .success(.updatedCredential(let credential)):
                    authManager.onUpdate(credential: credential, sessionUID: self.sessionId)
                    self.apiService.setSessionUID(uid: credential.UID)
                    completion(.success(credential))
                }
            }
        }
    }
    
    public func refreshUserInfo(completion: @escaping (Result<User, LoginError>) -> Void) {
        withAuthDelegateAvailable(completion) { authManager in
            guard let credential = authManager.credential(sessionUID: sessionId) else {
                completion(.failure(.invalidState))
                return
            }
            manager.getUserInfo(credential) {
                completion($0.mapError { $0.asLoginError() })
            }
        }
    }

    // MARK: - Data gathering entry point

    func handleValidCredentials(credential: Credential, passwordMode: PasswordMode, mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        self.mailboxPassword = mailboxPassword
        withAuthDelegateAvailable(completion) { authManager in
            authManager.onSessionObtaining(credential: credential)
            self.apiService.setSessionUID(uid: credential.UID)
            
            switch passwordMode {
            case .one:
                PMLog.debug("No mailbox password required, finishing up")
                getAccountDataPerformingAccountMigrationIfNeeded(user: nil, mailboxPassword: mailboxPassword, completion: completion)
            case .two:
                if minimumAccountType == .username {
                    completion(.success(.finished(LoginData.credential(credential))))
                    return
                }
                
                manager.getUserInfo(credential) { result in
                    switch result {
                    case let .success(user):
                        // This is because of a bug on the API, where accounts with no keys return PasswordMode = 2. (according to Android code)
                        guard user.keys.isEmpty else {
                            completion(.success(.askSecondPassword))
                            return
                        }
                        self.getAccountDataPerformingAccountMigrationIfNeeded(user: user, mailboxPassword: mailboxPassword, completion: completion)
                    case let .failure(error):
                        PMLog.debug("Getting user info failed with \(error)")
                        completion(.failure(error.asLoginError()))
                    }
                }
            }
        }
    }

    func withAuthDelegateAvailable<T>(_ completion: (Result<T, LoginError>) -> Void, continuation: (AuthDelegate) -> Void) {
        guard let authDelegate = apiService.authDelegate else {
            completion(.failure(.invalidState))
            return
        }
        continuation(authDelegate)
    }
}
