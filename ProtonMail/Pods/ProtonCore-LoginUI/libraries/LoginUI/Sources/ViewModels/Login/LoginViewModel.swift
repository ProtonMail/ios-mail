//
//  LoginViewModel.swift
//  ProtonCore-Login - Created on 04/11/2020.
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

#if os(iOS)

import Foundation
import ProtonCoreChallenge
import ProtonCoreLogin
import ProtonCoreDataModel
import ProtonCoreAuthentication
import ProtonCoreServices
import ProtonCoreNetworking
import ProtonCoreObservability

final class LoginViewModel {
    enum LoginResult {
        case done(LoginData)
        case twoFactorCodeNeeded
        case mailboxPasswordNeeded
        case createAddressNeeded(CreateAddressData, String?)
        case ssoChallenge(SSOChallengeResponse)
    }

    // MARK: - Properties

    let finished = Publisher<LoginResult>()
    let error = Publisher<LoginError>()
    let isLoading = Observable<Bool>(false)

    var isSsoUIEnabled = false
    let subtitleLabel = LUITranslation.screen_subtitle.l10n
    var loginTextFieldTitle: String {
        isSsoUIEnabled ? LUITranslation.email_field_title.l10n : LUITranslation.username_title.l10n
    }
    var titleLabel: String {
        isSsoUIEnabled ? LUITranslation.sign_in_with_sso_title.l10n : LUITranslation._core_sign_in_screen_title.l10n
    }
    var signInWithSSOButtonTitle: String {
        isSsoUIEnabled ? LUITranslation.sign_in_button_with_password.l10n : LUITranslation.sign_in_with_sso_button.l10n
    }
    let passwordTextFieldTitle = LUITranslation.password_title.l10n
    let signInButtonTitle = LUITranslation.sign_in_button.l10n
    let signUpButtonTitle = LUITranslation.create_account_button.l10n

    private let login: Login
    private let api: APIService
    let challenge: PMChallenge
    let clientApp: ClientApp

    init(api: APIService, login: Login, challenge: PMChallenge, clientApp: ClientApp) {
        self.api = api
        self.login = login
        self.challenge = challenge
        self.clientApp = clientApp
    }

    // MARK: - Actions

    func login(username: String, password: String) {
        self.challenge.appendCheckedUsername(username)
        isLoading.value = true

        let userFrame = ["name": "username"]
        let challengeData = self.challenge.export()
            .allFingerprintDict()
            .first(where: { $0["frame"] as? [String: String] == userFrame })
        let intent: Intent = isSsoUIEnabled ? .sso : .auto

        login.login(username: username, password: password, intent: intent, challenge: challengeData) { [weak self] result in
            switch result {
            case let .failure(error):
                self?.error.publish(error)
                self?.isLoading.value = false
            case let .success(status):
                switch status {
                case let .finished(data):
                    self?.finished.publish(.done(data))
                case .ask2FA:
                    self?.finished.publish(.twoFactorCodeNeeded)
                    self?.isLoading.value = false
                case .askSecondPassword:
                    self?.finished.publish(.mailboxPasswordNeeded)
                    self?.isLoading.value = false
                case .ssoChallenge(let ssoChallengeResponse):
                    self?.finished.publish(.ssoChallenge(ssoChallengeResponse))
                    self?.isLoading.value = false
                case let .chooseInternalUsernameAndCreateInternalAddress(data):
                    self?.login.availableUsernameForExternalAccountEmail(email: data.email) { [weak self] username in
                        self?.finished.publish(.createAddressNeeded(data, username))
                        self?.isLoading.value = false
                    }
                }
            }
        }
    }

    // MARK: - Validation

    func validate(username: String) -> Result<(), LoginValidationError> {
        return !username.isEmpty ? .success : .failure(.emptyUsername)
    }

    func validate(password: String) -> Result<(), LoginValidationError> {
        return !password.isEmpty ? .success : .failure(.emptyPassword)
    }

    func updateAvailableDomain(result: (([String]?) -> Void)? = nil) {
        login.updateAllAvailableDomains(type: .login) { res in result?(res) }
    }

    // MARK: - SSO

    func getSSOTokenFromURL(url: URL?) -> SSOResponseToken? {
        if let url = url,
           url.path == "/sso/login" {
            var components = URLComponents()
            components.query = url.fragment
            if let items = components.queryItems,
               let token = (items.first { $0.name == "token" }?.value),
               let uid = (items.first { $0.name == "uid" }?.value) {
                return .init(token: token, uid: uid)
            }
        }

        return nil
    }

    func getSSORequest(challenge ssoChallengeResponse: SSOChallengeResponse) async -> (request: URLRequest?, error: String?) {
        await login.getSSORequest(challenge: ssoChallengeResponse)
    }

    func processResponseToken(idpEmail: String, responseToken: SSOResponseToken) {
        isLoading.value = true
        login.processResponseToken(idpEmail: idpEmail, responseToken: responseToken) { [weak self] result in
            switch result {
            case .success(.finished(let data)):
                ObservabilityEnv.report(.ssoIdentityProviderLoginResult(status: .successful))
                self?.finished.publish(.done(data))
            case let .failure(error):
                ObservabilityEnv.report(.ssoIdentityProviderLoginResult(status: .failed))
                self?.error.publish(error)
                self?.isLoading.value = false
            default:
                self?.error.publish(.invalidState)
                self?.isLoading.value = false
            }
        }
    }

    func isProtonPage(url: URL?) -> Bool {
        login.isProtonPage(url: url)
    }
}

#endif
