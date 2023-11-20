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
import ProtonCoreAPIClient
import ProtonCoreAuthentication
import ProtonCoreAuthenticationKeyGeneration
import ProtonCoreDataModel
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreObservability

extension LoginService {

    public func processResponseToken(idpEmail: String, responseToken: SSOResponseToken, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        if responseToken.uid != apiService.sessionUID,
           responseToken.uid.caseInsensitiveCompare("notimplementedyet") != .orderedSame {
            assertionFailure("response token UID is not equal to apiService UID and it should.")
        }
        authenticateWithSSO(idpEmail: idpEmail, responseToken: responseToken, completion: completion)
    }

    public func getSSORequest(challenge ssoChallengeResponse: SSOChallengeResponse) async -> (request: URLRequest?, error: String?) {
        let accessToken: (token: String?, error: String?) = await withCheckedContinuation { continuation in
            apiService.fetchAuthCredentials { result in
                switch result {
                case .found(let credentials):
                    continuation.resume(returning: (credentials.accessToken, nil))
                case .notFound:
                    continuation.resume(returning: (nil, AuthCredentialFetchingResult.notFound.toNSError?.localizedDescription))
                case .wrongConfigurationNoDelegate:
                    continuation.resume(returning: (nil, AuthCredentialFetchingResult.wrongConfigurationNoDelegate.toNSError?.localizedDescription))
                }
            }
        }

        if let error = accessToken.error, accessToken.token == nil {
            return (nil, error)
        }

        let host = apiService.dohInterface.getCurrentlyUsedHostUrl()
        let sessionUID = apiService.sessionUID

        let url = URL(string: "\((host))/auth/sso/\(ssoChallengeResponse.ssoChallengeToken)")!
        var request = URLRequest(url: url)
        request.setValue(sessionUID, forHTTPHeaderField: "x-pm-uid")
        request.setValue(accessToken.token, forHTTPHeaderField: "Authorization")

        return (request, nil)
    }

    public func isProtonPage(url: URL?) -> Bool {
        guard let url else { return false }
        let hosts = [
            apiService.dohInterface.getAccountHost(),
            apiService.dohInterface.getCurrentlyUsedHostUrl(),
            apiService.dohInterface.getHumanVerificationV3Host(),
            apiService.dohInterface.getCaptchaHostUrl()
        ]
        return hosts.contains(where: url.absoluteString.contains)
    }

    private func authenticateWithSSO(idpEmail: String, responseToken: SSOResponseToken, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        withAuthDelegateAvailable(completion) { authManager in
            manager.authenticate(idpEmail: idpEmail, responseToken: responseToken) { result in
                switch result {
                case let .success(status):
                    switch status {
                    case let .newCredential(credential, passwordMode):
                        self.handleValidCredentials(credential: credential, passwordMode: passwordMode, mailboxPassword: nil, isSSO: true, completion: completion)
                    case .updatedCredential, .ssoChallenge, .ask2FA:
                        completion(.failure(.invalidState))
                    }

                case let .failure(error):
                    PMLog.debug("Login failed with \(error)")
                    completion(.failure(error.asLoginError()))
                }
            }
        }
    }

    public func login(username: String, password: String, challenge: [String: Any]?, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        login(username: username, password: password, intent: nil, challenge: challenge, completion: completion)
    }

    public func login(username: String, password: String, intent: Intent?, challenge: [String: Any]?, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        withAuthDelegateAvailable(completion) { authManager in
            self.username = username
            self.mailboxPassword = password
            var data: ChallengeProperties?
            if let challenge = challenge {
                data = ChallengeProperties(challenge: challenge, productPrefix: self.clientApp.name)
            }
            PMLog.debug("Logging in with username and password")

            manager.authenticate(username: username, password: password, challenge: data, intent: intent, srpAuth: nil) { result in
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
                        authManager.onSessionObtaining(credential: credential)
                        self.apiService.setSessionUID(uid: credential.UID)
                        PMLog.debug("No idea how to handle updatedCredential")
                        completion(.failure(.invalidState))
                    case .ssoChallenge(let ssoChallengeResponse):
                        completion(.success(.ssoChallenge(ssoChallengeResponse)))
                    }

                case let .failure(error):
                    PMLog.debug("Login failed with \(error)")
                    if case let .networkingError(error) = error, error.isSwitchToSRPError {
                        ObservabilityEnv.report(.ssoObtainChallengeToken(status: .ssoDomainNotFound))
                    }
                    completion(.failure(error.asLoginError()))
                }
            }
        }
    }

    public func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        withAuthDelegateAvailable(completion) { authManager in
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
                        authManager.onSessionObtaining(credential: credential)
                        self.apiService.setSessionUID(uid: credential.UID)
                        PMLog.debug("No idea how to handle updatedCredential")
                        completion(.failure(.invalidState))
                    case .ssoChallenge:
                        PMLog.debug("Obtaining SSO challenge should never happen")
                        completion(.failure(.invalidState))
                    }
                case let .failure(error):
                    PMLog.debug("Confirming 2FA code failed with \(error)")
                    let loginError = error.asLoginError(in2FAContext: true)
                    completion(.failure(loginError))
                }
            }
        }
    }

    public func finishLoginFlow(mailboxPassword: String, passwordMode: PasswordMode, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        manager.getUserInfo { result in
            switch result {
            case .success(let user):
                self.getAccountDataPerformingAccountMigrationIfNeeded(
                    user: user, mailboxPassword: mailboxPassword, passwordMode: passwordMode, completion: completion
                )
            case .failure(let error):
                PMLog.debug("Fetching user info with \(error)")
                completion(.failure(error.asLoginError()))
            }
        }
    }

    public func logout(credential: AuthCredential? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        PMLog.debug("Logging out")

        manager.closeSession(credential.map(Credential.init)) { result in
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

        if let protonDomain = allSignUpDomains.first(where: { email.hasSuffix("@\($0)") }) {
            let suffix = "@\(protonDomain)"
            let username = String(email.dropLast(suffix.count))
            // this message is provided just in case this error is not handled properly due to a bug
            let nonUserFacingMessage = "The email address you provided is Proton Mail address. Please create Proton Mail account."
            completion(.failure(.protonDomainUsedForExternalAccount(
                username: username, domain: protonDomain, nonUserFacingMessage: nonUserFacingMessage
            )))
            return
        }

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

                        case let .failure(.apiMightBeBlocked(message, originalError)):
                            completion(.failure(.apiMightBeBlocked(message: message, originalError: originalError)))
                        case let .failure(error):
                            completion(.failure(.generic(message: error.userFacingMessageInNetworking, code: error.codeInNetworking, originalError: error)))
                        }
                    }
                case .apiMightBeBlocked(let message, let originalError):
                    completion(.failure(.apiMightBeBlocked(message: message, originalError: originalError)))
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
            completion(.failure(.generic(message: LSTranslation._loginservice_error_generic.l10n,
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
                    completion(.failure(.generic(message: LSTranslation._loginservice_error_generic.l10n,
                                                 code: 0,
                                                 originalError: LoginError.invalidState)))
                    return
                }

                self.manager.createAddressKey(user: user, address: address,
                                              password: mailboxPassword, salt: salt, isPrimary: true) { result in
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

    public func availableUsernameForExternalAccountEmail(email: String, completion: @escaping (String?) -> Void) {
        guard let username = email.components(separatedBy: "@").first else {
            completion(nil)
            return
        }
        checkAvailabilityForInternalAccount(username: username) { result in
            switch result {
            case .success:
                completion(username)
            case .failure:
                // we ignore the error and just return nil by design
                // reason being — this method is used for checking if the username
                // we want to propose to the user converting from external to internal account
                // is available. if we cannot confirm it, we don't want to block the user.
                // we just won't propose them the username, but we will let them choose their own one
                completion(nil)
            }
        }
    }
}
