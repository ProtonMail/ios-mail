//
//  SignInService.swift
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
import ProtonCore_APIClient
import ProtonCore_Authentication
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services

final class LoginService {

    typealias AuthenticationManager = AuthenticatorInterface & AuthenticatorKeyGenerationInterface

    // MARK: - Properties

    let apiService: APIService
    let manager: AuthenticationManager
    var context: TwoFactorContext?
    var mailboxPassword: String?
    var minimumAccountType: AccountType
    var username: String?
    let authManager: AuthManager

    var defaultSignUpDomain = "protonmail.com"
    var updatedSignUpDomain: String?
    var signUpDomain: String {
        return updatedSignUpDomain ?? defaultSignUpDomain
    }

    init(api: APIService, authManager: AuthManager, minimumAccountType: AccountType, authenticator: AuthenticationManager? = nil) {
        self.apiService = api
        self.minimumAccountType = minimumAccountType
        self.authManager = authManager
        manager = authenticator ?? Authenticator(api: api)
    }

    // MARK: - Configuration

    func updateAccountType(accountType: AccountType) {
        minimumAccountType = accountType
    }

    func updateAvailableDomain(type: AvailableDomainsType, result: @escaping (String?) -> Void) {
        updatedSignUpDomain = nil
        availableDomains(type: type) { res in
            switch res {
            case .success(let domains):
                if let domain = domains.first {
                    self.updatedSignUpDomain = domain
                    result(domain)
                }
            case .failure:
                self.updatedSignUpDomain = nil
                result(nil)
            }
        }
    }

    private func availableDomains(type: AvailableDomainsType, completion: @escaping (Result<([String]), LoginError>) -> Void) {
        let route = AvailableDomainsRequest(type: type)

        apiService.exec(route: route) { (result: Result<AvailableDomainResponse, ResponseError>) in
            switch result {
            case .failure(let error):
                completion(.failure(LoginError.generic(message: error.localizedDescription)))
            case .success(let response):
                completion(.success(response.domains))
            }
        }
    }

    // MARK: - Data gathering entry point

    func handleValidCredentials(credential: Credential, passwordMode: PasswordMode, mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        self.mailboxPassword = mailboxPassword
        authManager.setCredential(auth: credential)

        switch passwordMode {
        case .one:
            PMLog.debug("No mailbox password required, finishing up")
            getAccountDataPerformingAccountMigrationIfNeeded(user: nil, mailboxPassword: mailboxPassword, completion: completion)
        case .two:
            manager.getUserInfo(credential) { result in
                switch result {
                case let .success(user):
                    // This is because of a bug on the API, where accounts with no keys return PasswordMode = 2. (according to Android code)
                    guard user.keys.isEmpty else {
                        completion(.success(.askSecondPassword))
                        return
                    }

                    if self.minimumAccountType == .username {
                        if let key = user.keys.first(where: { $0.primary == 1 }) ?? user.keys.first {
                            self.authManager.updateAuth(password: nil, salt: nil, privateKey: key.privateKey)
                        }

                        completion(.success(.finished(LoginData(credential: self.authManager.getToken(bySessionUID: PMLogin.sessionId)!, user: user, salts: [], passphrases: [:], addresses: [], scopes: self.authManager.scopes ?? []))))
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
