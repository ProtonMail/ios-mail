//
//  LoginService+Login.swift
//  ProtonCore-Login - Created on 18.01.2021.
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
import ProtonCore_Authentication
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_CoreTranslation
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Networking

extension LoginService {

    public func login(username: String, password: String, challenge: [String: Any]?, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        self.username = username
        self.mailboxPassword = password
        var data: ChallengeProperties?
        if let challenge = challenge {
            data = ChallengeProperties(challengeData: challenge, productPrefix: self.clientApp.name)
        }
        PMLog.debug("Logging in with username and password")

        manager.authenticate(username: username, password: password, challenge: data, srpAuth: nil) { result in
            switch result {
            case let .success(status):
                switch status {
                case let .ask2FA(context):
                    self.context = context
                    PMLog.debug("Login successful but needs 2FA code")
                    completion(.success(.ask2FA))
                case let .newCredential(credential, passwordMode):
                    self.context = (credential: credential, passwordMode: passwordMode)
                    self.handleValidCredentials(credential: credential, passwordMode: passwordMode, mailboxPassword: password, completion: completion)
                case .updatedCredential(let credential):
                    self.authManager.setCredential(auth: credential)
                    PMLog.debug("No idea how to handle updatedCredential")
                    completion(.failure(.invalidState))
                }

            case let .failure(error):
                PMLog.debug("Login failed with \(error)")
                completion(.failure(error.asLoginError()))
            }
        }
    }

    public func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        PMLog.debug("Confirming 2FA code")
        guard let context = self.context else {
            completion(.failure(.invalidState))
            return
        }

        guard let mailboxPassword = mailboxPassword else {
            completion(.failure(.invalidState))
            return
        }

        manager.confirm2FA(code, context: context) { result in
            switch result {
            case let .success(status):
                switch status {
                case let .newCredential(credential, passwordMode):
                    PMLog.debug("2FA code accepted, updating the credentials context and moving further")
                    self.context = (credential: credential, passwordMode: passwordMode)
                    self.handleValidCredentials(credential: credential, passwordMode: passwordMode, mailboxPassword: mailboxPassword, completion: completion)

                case .ask2FA:
                    PMLog.debug("Asking afaing for 2FA code should never happen")
                    completion(.failure(.invalidState))

                case .updatedCredential(let credential):
                    self.authManager.setCredential(auth: credential)
                    PMLog.debug("No idea how to handle updatedCredential")
                    completion(.failure(.invalidState))
                }
            case let .failure(error):
                PMLog.debug("Confirming 2FA code failed with \(error)")
                let loginError = error.asLoginError(in2FAContext: true)
                completion(.failure(loginError))
            }
        }
    }

    public func finishLoginFlow(mailboxPassword: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        getAccountDataPerformingAccountMigrationIfNeeded(user: nil, mailboxPassword: mailboxPassword, completion: completion)
    }

    public func logout(credential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        PMLog.debug("Logging out")

        manager.closeSession(Credential(credential)) { result in
            switch result {
            case .success:
                completion(.success)
            case let .failure(error):
                PMLog.debug("Logout failed with \(error)")
                completion(.failure(error))
            }
        }
    }

    public func checkAvailabilityForUsernameAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        PMLog.debug(#function)

        manager.checkAvailableUsernameWithoutSpecifyingDomain(username) { result in
            completion(result.mapError { $0.asAvailabilityError() })
        }
    }
    
    public func checkAvailabilityForInternalAccount(username: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        PMLog.debug(#function)
        
        manager.checkAvailableUsernameWithinDomain(username, domain: currentlyChosenSignUpDomain) { result in
            completion(result.mapError { $0.asAvailabilityError() })
        }
    }
    
    public func checkAvailabilityForExternalAccount(email: String, completion: @escaping (Result<(), AvailabilityError>) -> Void) {
        PMLog.debug(#function)

        manager.checkAvailableExternal(email) { result in
            completion(result.mapError { $0.asAvailabilityError() })
        }
    }

    public func setUsername(username: String, completion: @escaping (Result<(), SetUsernameError>) -> Void) {
        PMLog.debug("Setting username")

        manager.setUsername(username: username) { result in
            switch result {
            case .success:
                completion(.success)
            case let .failure(error):
                completion(.failure(error.asSetUsernameError()))
            }
        }
    }

    public func createAccountKeysIfNeeded(user: User,
                                          addresses: [Address]?,
                                          mailboxPassword: String?,
                                          completion: @escaping (Result<User, LoginError>) -> Void) {
        PMLog.debug("Creating account keys if needed")
        let isAccountKeyCreationNeeded = user.keys.first(where: { $0.primary == 1 }) == nil
        guard isAccountKeyCreationNeeded else {
            PMLog.debug("No need to create account key, moving forward")
            completion(.success(user))
            return
        }
        guard let mailboxPassword = mailboxPassword else {
            PMLog.error("Cannot create account key because no mailbox password")
            completion(.failure(.invalidState))
            return
        }

        // if no info about addresses was provided from the client, refresh it
        startGeneratingKeys?()
        guard let addresses = addresses else {
            manager.getAddresses { [weak self] in
                switch $0 {
                case .success(let addresses):
                    self?.createAccountKeysIfNeeded(user: user, addresses: addresses, mailboxPassword: mailboxPassword, completion: completion)
                case .failure(let error):
                    PMLog.debug("Login failed with \(error)")
                    completion(.failure(error.asLoginError()))
                }
            }
            return
        }

        guard !addresses.isEmpty else {
            PMLog.debug("No addresses means no need to create account key, moving forward")
            completion(.success(user))
            return
        }

        if addresses.filter({ $0.type != .externalAddress }).isEmpty {
            PMLog.debug("No internal addresses means no need to create account key, moving forward")
            completion(.success(user))
            return
        }
        
        PMLog.debug("Creating account keys")
        let manager = self.manager
        manager.setupAccountKeys(addresses: addresses, password: mailboxPassword) { result in
            switch result {
            case let .failure(error):
                PMLog.error("Cannot create account keys for user")
                completion(.failure(error.asLoginError()))
            case .success:
                manager.getUserInfo { result in
                    switch result {
                    case .success(let user):
                        PMLog.debug("Keys set up, moving forward")
                        completion(.success(user))
                    case .failure(let error):
                        PMLog.debug("Cannot refresh user state after keys creation")
                        completion(.failure(error.asLoginError()))
                    }
                }
            }
        }
    }

    public func createAddress(completion: @escaping (Result<Address, CreateAddressError>) -> Void) {
        PMLog.debug("Creating address with domain \(currentlyChosenSignUpDomain)")

        startGeneratingAddress?()
        manager.createAddress(domain: currentlyChosenSignUpDomain) { result in
            switch result {
            case let .success(address):
                completion(.success(address))
            case let .failure(error):
                switch error {
                case .networkingError(let responseError) where responseError.responseCode == 2011:
                    self.manager.getAddresses { result in
                        switch result {
                        case let .success(addresses):
                            if let internalOrCustomDomainAddress = addresses.first(where: { $0.isInternal || $0.isCustomDomain }) {
                                completion(.failure(.alreadyHaveInternalOrCustomDomainAddress(internalOrCustomDomainAddress)))
                            } else {
                                completion(.failure(.cannotCreateInternalAddress(alreadyExistingAddress: addresses.first)))
                            }

                        case let .failure(error):
                            completion(.failure(.generic(message: error.userFacingMessageInNetworking, code: error.codeInNetworking, originalError: error)))
                        }
                    }
                default:
                    completion(.failure(.generic(message: error.userFacingMessageInNetworking, code: error.codeInNetworking, originalError: error)))
                }
            }
        }
    }

    public func createAddressKeys(user: User, address: Address, mailboxPassword: String, completion: @escaping (Result<Key, CreateAddressKeysError>) -> Void) {
        PMLog.debug("Creating address keys")

        guard address.keys.isEmpty else {
            completion(.failure(.alreadySet))
            return
        }

        guard let primaryKey = user.keys.first(where: { $0.primary == 1 }) else {
            PMLog.error("Cannot create address for user without primary key")
            completion(.failure(.generic(message: CoreString._ls_error_generic,
                                         code: 0,
                                         originalError: LoginError.invalidState)))
            return
        }

        manager.getKeySalts { result in
            switch result {
            case let .failure(error):
                completion(.failure(error.asCreateAddressKeysError()))
            case let .success(salts):
                guard let keySalt = salts.first(where: { $0.ID == primaryKey.keyID })?.keySalt, let salt = Data(base64Encoded: keySalt) else {
                    PMLog.error("Missing salt for primary key")
                    completion(.failure(.generic(message: CoreString._ls_error_generic,
                                                 code: 0,
                                                 originalError: LoginError.invalidState)))
                    return
                }

                self.manager.createAddressKey(address: address, password: mailboxPassword, salt: salt, primary: true) { result in
                    switch result {
                    case let .success(key):
                        completion(.success(key))
                    case let .failure(error):
                        completion(.failure(error.asCreateAddressKeysError()))
                    }
                }
            }
        }
    }
}
