//
//  Container.swift
//  PMLogin - Created on 30.11.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import TrustKit
import ProtonCore_APIClient
import ProtonCore_Challenge
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_HumanVerification
import ProtonCore_Networking
import ProtonCore_Services

final class Container {
    let login: Login
    let signupService: Signup

    private let api: PMAPIService
    private let authManager: AuthManager
    private var humanCheckHelper: HumanCheckHelper?
    private var paymentsCoordinator: PaymentsCoordinator?
    private let externalLinks = ExternalLinks()
    private let appName: String
    private let challenge: PMChallenge

    init(appName: String, doh: DoH, apiServiceDelegate: APIServiceDelegate, forceUpgradeDelegate: ForceUpgradeDelegate, minimumAccountType: AccountType) {
        // TODO: should we introduce the proper pinning into the sample app?
        let trustKit = TrustKit()
        trustKit.pinningValidator = .init()
        PMAPIService.trustKit = trustKit
        api = PMAPIService(doh: doh, sessionUID: PMLogin.sessionId)
        api.forceUpgradeDelegate = forceUpgradeDelegate
        api.serviceDelegate = apiServiceDelegate
        authManager = AuthManager()
        api.authDelegate = authManager
        login = LoginService(api: api, authManager: authManager, minimumAccountType: minimumAccountType)
        challenge = PMChallenge()
        signupService = SignupService(api: api, challenge: challenge)
        self.appName = appName
    }

    // MARK: Login view models

    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(login: login)
    }

    func makeCreateAddressViewModel(username: String, data: CreateAddressData, updateUser: @escaping (User) -> Void) -> CreateAddressViewModel {
        return CreateAddressViewModel(username: username, login: login, data: data, updateUser: updateUser)
    }

    func makeChooseUsernameViewModel(data: CreateAddressData) -> ChooseUsernameViewModel {
        return ChooseUsernameViewModel(data: data, login: login, appName: appName)
    }

    func makeMailboxPasswordViewModel() -> MailboxPasswordViewModel {
        return MailboxPasswordViewModel(login: login)
    }

    func makeTwoFactorViewModel() -> TwoFactorViewModel {
        return TwoFactorViewModel(login: login)
    }

    // MARK: Signup view models

    func makeSignupViewModel() -> SignupViewModel {
        return SignupViewModel(apiService: api, signupService: signupService, loginService: login, challenge: challenge)
    }

    func makePasswordViewModel() -> PasswordViewModel {
        return PasswordViewModel()
    }

    func makeRecoveryViewModel(initialCountryCode: Int) -> RecoveryViewModel {
        return RecoveryViewModel(initialCountryCode: initialCountryCode, challenge: challenge)
    }

    func makeCompleteViewModel(deviceToken: String) -> CompleteViewModel {
        return CompleteViewModel(signupService: signupService, loginService: login, deviceToken: deviceToken)
    }

    func makeTCViewModel() -> TCViewModel {
        return TCViewModel()
    }

    func makeEmailVerificationViewModel() -> EmailVerificationViewModel {
        return EmailVerificationViewModel(apiService: api, signupService: signupService)
    }
    
    func makePaymentsCoordinator(receipt: String?) -> PaymentsCoordinator {
        let paymentsCoordinator = PaymentsCoordinator(apiService: api, receipt: receipt)
        self.paymentsCoordinator = paymentsCoordinator
        return paymentsCoordinator
    }

    // MARK: Other view models

    func makeExternalLinks() -> ExternalLinks {
        return externalLinks
    }

    func setupHumanVerification(viewController: UIViewController? = nil) {
        let url = externalLinks.humanVerificationHelp
        humanCheckHelper = HumanCheckHelper(apiService: api, supportURL: url, viewController: viewController, responseDelegate: nil, paymentDelegate: self)
        api.humanDelegate = humanCheckHelper
    }

}

extension Container: HumanVerifyPaymentDelegate {
    var paymentToken: String? {
        return paymentsCoordinator?.tokenStorage?.get()?.token
    }
    
    func paymentTokenStatusChanged(status: PaymentTokenStatusResult) {

    }

}
