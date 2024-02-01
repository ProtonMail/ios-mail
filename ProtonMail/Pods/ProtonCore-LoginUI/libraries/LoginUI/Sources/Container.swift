//
//  Container.swift
//  ProtonCore-Login - Created on 30.11.2020.
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
import TrustKit
import ProtonCoreAPIClient
import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreDataModel
import ProtonCoreDoh
import ProtonCoreHumanVerification
import ProtonCoreFoundations
import ProtonCoreLogin
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices
import typealias ProtonCorePayments.ListOfIAPIdentifiers
import typealias ProtonCorePayments.ListOfShownPlanNames
import typealias ProtonCorePayments.BugAlertHandler
import ProtonCorePaymentsUI
import ProtonCoreTroubleShooting
import ProtonCoreEnvironment
import ProtonCoreFeatureSwitch

final class Container {
    let login: Login
    let signupService: Signup

    private(set) var api: APIService
    private var paymentsManager: PaymentsManager?
    private let externalLinks: ExternalLinks
    private let clientApp: ClientApp
    private let appName: String
    let challenge: PMChallenge
    let troubleShootingHelper: TroubleShootingHelper

    var token: String?
    var tokenType: String?

    init(appName: String,
         clientApp: ClientApp,
         apiService: APIService,
         minimumAccountType: AccountType) {

        self.appName = appName
        self.clientApp = clientApp
        self.externalLinks = ExternalLinks(clientApp: clientApp)
        self.troubleShootingHelper = TroubleShootingHelper(doh: apiService.dohInterface)
        self.api = apiService
        self.api.acquireSessionIfNeeded { result in
            #if DEBUG
            PMLog.debug("\(result)")
            #endif
        }
        self.login = LoginService(api: apiService, clientApp: clientApp, minimumAccountType: minimumAccountType)
        self.signupService = SignupService(api: apiService, clientApp: clientApp)

        if let challenge = apiService.challengeParametersProvider.challenge {
            self.challenge = challenge
        } else {
            assertionFailure("Misconfiguration of APIService.challengeParametersProvider")
            let newChallenge = PMChallenge()
            self.challenge = newChallenge
            api.challengeParametersProvider = .forAPIService(clientApp: clientApp, challenge: newChallenge)
        }
    }

    func registerHumanVerificationDelegates() {
        api.humanDelegate?.responseDelegateForLoginAndSignup = self
        api.humanDelegate?.paymentDelegateForLoginAndSignup = self
    }

    func unregisterHumanVerificationDelegates() {
        api.humanDelegate?.responseDelegateForLoginAndSignup = nil
        api.humanDelegate?.paymentDelegateForLoginAndSignup = nil
    }

    // MARK: Login view models

    func makeLoginViewModel() -> LoginViewModel {
        challenge.reset()
        return LoginViewModel(api: api, login: login, challenge: challenge, clientApp: clientApp)
    }

    func makeCreateAddressViewModel(data: CreateAddressData, defaultUsername: String?) -> CreateAddressViewModel {
        return CreateAddressViewModel(data: data, login: login, defaultUsername: defaultUsername)
    }

    func makeMailboxPasswordViewModel() -> MailboxPasswordViewModel {
        return MailboxPasswordViewModel(login: login)
    }

    func makeTwoFactorViewModel(username: String, password: String) -> TwoFactorViewModel {
        return TwoFactorViewModel(login: login, username: username, password: password)
    }

    // MARK: Signup view models

    func makeSignupViewModel() -> SignupViewModel {
        challenge.reset()
        return SignupViewModel(signupService: signupService,
                               loginService: login,
                               challenge: challenge)
    }

    func makePasswordViewModel() -> PasswordViewModel {
        return PasswordViewModel()
    }

    func makeRecoveryViewModel(initialCountryCode: Int) -> RecoveryViewModel {
        return RecoveryViewModel(signupService: signupService, initialCountryCode: initialCountryCode, challenge: challenge)
    }

    func makeCompleteViewModel(initDisplaySteps: [DisplayProgressStep]) -> CompleteViewModel {
        return CompleteViewModel(signupService: signupService, loginService: login, initDisplaySteps: initDisplaySteps)
    }

    func makeEmailVerificationViewModel() -> EmailVerificationViewModel {
        return EmailVerificationViewModel(signupService: signupService)
    }

    func makeSummaryViewModel(planName: String?,
                              paymentsAvailability: PaymentsAvailability,
                              screenVariant: SummaryScreenVariant) -> SummaryViewModel {
        return SummaryViewModel(planName: planName, paymentsAvailability: paymentsAvailability,
                                screenVariant: screenVariant, clientApp: clientApp)
    }

    func makePaymentsCoordinator(for iaps: ListOfIAPIdentifiers, shownPlanNames: ListOfShownPlanNames, customization: PaymentsUICustomizationOptions, reportBugAlertHandler: BugAlertHandler) -> PaymentsManager {
        let paymentsManager = PaymentsManager(apiService: api, iaps: iaps, shownPlanNames: shownPlanNames, clientApp: clientApp, customization: customization, reportBugAlertHandler: reportBugAlertHandler)
        self.paymentsManager = paymentsManager
        return paymentsManager
    }

    // MARK: Other view models

    func makeExternalLinks() -> ExternalLinks {
        return externalLinks
    }
}

extension Container: HumanVerifyPaymentDelegate {
    var paymentToken: String? {
        return paymentsManager?.tokenStorage?.get()?.token
    }

    func paymentTokenStatusChanged(status: PaymentTokenStatusResult) {

    }
}

extension Container: HumanVerifyResponseDelegate {
    func onHumanVerifyStart() { }

    func onHumanVerifyEnd(result: HumanVerifyEndResult) { }

    func humanVerifyToken(token: String?, tokenType: String?) {
        self.token = token
        self.tokenType = tokenType
    }
}

extension Container {
    func executeDohTroubleshootMethodFromApiDelegate() {
        api.serviceDelegate?.onDohTroubleshot()
    }
}

#endif
