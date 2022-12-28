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
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import typealias ProtonCore_Payments.ListOfIAPIdentifiers
import typealias ProtonCore_Payments.ListOfShownPlanNames
import typealias ProtonCore_Payments.BugAlertHandler
import ProtonCore_PaymentsUI
import ProtonCore_TroubleShooting
import ProtonCore_Environment

extension PMChallenge: ChallangeParametersProvider {
    public func provideParameters() -> [[String: Any]] {
        export().toDictArray()
    }
}

final class Container {
    let login: Login
    let signupService: Signup
    let authManager: AuthHelper
    
    let api: PMAPIService
    private var humanCheckHelper: HumanCheckHelper?
    private var paymentsManager: PaymentsManager?
    private let externalLinks: ExternalLinks
    private let clientApp: ClientApp
    private let appName: String
    private let challenge: PMChallenge
    let troubleShootingHelper: TroubleShootingHelper
    
    var token: String?
    var tokenType: String?
    
    @available(*, deprecated,
                renamed: "init(appName:clientApp:doh:apiServiceDelegate:forceUpgradeDelegate:minimumAccountType:)",
                message: "HumanVerificationVersion is removed")
    convenience init(appName: String,
                     clientApp: ClientApp,
                     doh: DoHInterface,
                     trustKit: TrustKit? = nil,
                     apiServiceDelegate: APIServiceDelegate,
                     forceUpgradeDelegate: ForceUpgradeDelegate,
                     humanVerificationVersion: HumanVerificationVersion,
                     minimumAccountType: AccountType) {
        
        self.init(appName: appName, clientApp: clientApp, doh: doh, trustKit: trustKit,
                  apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate,
                    minimumAccountType: minimumAccountType)
    }
    
    @available(*, deprecated,
                renamed: "init(appName:clientApp:environment:apiServiceDelegate:orceUpgradeDelegate:minimumAccountType:)",
                message: "HumanVerificationVersion is removed")
    convenience init(appName: String,
                     clientApp: ClientApp,
                     environment: Environment,
                     trustKit: TrustKit? = nil,
                     apiServiceDelegate: APIServiceDelegate,
                     forceUpgradeDelegate: ForceUpgradeDelegate,
                     humanVerificationVersion: HumanVerificationVersion,
                     minimumAccountType: AccountType) {
        
        self.init(appName: appName, clientApp: clientApp, doh: environment.doh, trustKit: trustKit,
                  apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate, minimumAccountType: minimumAccountType)
    }
    
    convenience init(appName: String,
                     clientApp: ClientApp,
                     environment: Environment,
                     trustKit: TrustKit? = nil,
                     apiServiceDelegate: APIServiceDelegate,
                     forceUpgradeDelegate: ForceUpgradeDelegate,
                     minimumAccountType: AccountType) {
        
        self.init(appName: appName, clientApp: clientApp, doh: environment.doh, trustKit: trustKit,
                  apiServiceDelegate: apiServiceDelegate, forceUpgradeDelegate: forceUpgradeDelegate,
                  minimumAccountType: minimumAccountType)
    }
    
    init(appName: String,
         clientApp: ClientApp,
         doh: DoHInterface,
         trustKit: TrustKit? = nil,
         apiServiceDelegate: APIServiceDelegate,
         forceUpgradeDelegate: ForceUpgradeDelegate,
         minimumAccountType: AccountType) {
        
        // use the TrustKit instance passed from the outside
        if let trustKit = trustKit {
            PMAPIService.trustKit = trustKit
        }
        
        if PMAPIService.trustKit == nil {
            let trustKit = TrustKit()
            trustKit.pinningValidator = .init()
            PMAPIService.trustKit = trustKit
        }
        
        api = PMAPIService(doh: doh)
        api.forceUpgradeDelegate = forceUpgradeDelegate
        api.serviceDelegate = apiServiceDelegate
        authManager = AuthHelper()
        api.authDelegate = authManager
        login = LoginService(api: api, authManager: authManager, clientApp: clientApp, minimumAccountType: minimumAccountType)
        challenge = PMChallenge()
        signupService = SignupService(api: api, challangeParametersProvider: challenge, clientApp: clientApp)
        self.appName = appName
        self.clientApp = clientApp
        self.externalLinks = ExternalLinks(clientApp: clientApp)
        self.troubleShootingHelper = TroubleShootingHelper.init(doh: doh)
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
        return SignupViewModel(apiService: api,
                               signupService: signupService,
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
        return EmailVerificationViewModel(apiService: api, signupService: signupService)
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
    
    func setupHumanVerification(viewController: UIViewController? = nil) {
        let nonModalUrl = URL(string: "/users/availableExternal")!
        humanCheckHelper = HumanCheckHelper(apiService: api,
                                            viewController: viewController,
                                            nonModalUrls: [nonModalUrl],
                                            clientApp: clientApp,
                                            responseDelegate: self,
                                            paymentDelegate: self)
        api.humanDelegate = humanCheckHelper
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
