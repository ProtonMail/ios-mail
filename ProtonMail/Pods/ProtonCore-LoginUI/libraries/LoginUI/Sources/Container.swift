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

import Foundation
import TrustKit
import ProtonCore_APIClient
import ProtonCore_Authentication
import ProtonCore_Challenge
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_HumanVerification
import ProtonCore_Foundations
import ProtonCore_Login
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services
import typealias ProtonCore_Payments.ListOfIAPIdentifiers
import typealias ProtonCore_Payments.ListOfShownPlanNames
import typealias ProtonCore_Payments.BugAlertHandler
import ProtonCore_PaymentsUI
import ProtonCore_TroubleShooting
import ProtonCore_Environment
import ProtonCore_FeatureSwitch

final class Container {
    let login: Login
    let signupService: Signup
    
    let api: APIService
    private var paymentsManager: PaymentsManager?
    private let externalLinks: ExternalLinks
    private let clientApp: ClientApp
    private let appName: String
    private let challenge: PMChallenge
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
        if FeatureFactory.shared.isEnabled(.unauthSession) {
            self.api.acquireSessionIfNeeded { result in PMLog.debug("\(result)") }
        }
        self.login = LoginService(api: apiService, clientApp: clientApp, minimumAccountType: minimumAccountType)
        self.challenge = PMChallenge()
        self.signupService = SignupService(api: apiService, clientApp: clientApp)
    }

    // MARK: Login view models
    
    func makeLoginViewModel() -> LoginViewModel {
        challenge.reset()
        return LoginViewModel(login: login, challenge: challenge)
    }
    
    func makeCreateAddressViewModel(data: CreateAddressData, defaultUsername: String?) -> CreateAddressViewModel {
        return CreateAddressViewModel(data: data, login: login, defaultUsername: defaultUsername)
    }
    
    func makeMailboxPasswordViewModel() -> MailboxPasswordViewModel {
        return MailboxPasswordViewModel(login: login)
    }
    
    func makeTwoFactorViewModel() -> TwoFactorViewModel {
        return TwoFactorViewModel(login: login)
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
    
    func makePaymentsCoordinator(for iaps: ListOfIAPIdentifiers, shownPlanNames: ListOfShownPlanNames, reportBugAlertHandler: BugAlertHandler) -> PaymentsManager {
        let paymentsManager = PaymentsManager(apiService: api, iaps: iaps, shownPlanNames: shownPlanNames, clientApp: clientApp, reportBugAlertHandler: reportBugAlertHandler)
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
