//
//  SignInCoordinatorEnvironment.swift
//  ProtonMail - Created on 30/04/2021
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_LoginUI
import ProtonCore_Networking
import ProtonCore_Services
import UIKit

struct SignInCoordinatorEnvironment {
    typealias LoginCreationClosure = (String, AccountType, SignupMode, SignupPasswordRestrictions, Bool) -> LoginAndSignupInterface

    let services: ServiceFactory
    let doh: DoH & ServerConfig
    let forceUpgradeDelegate: ForceUpgradeDelegate
    let apiServiceDelegate: APIServiceDelegate
    let mailboxPassword: (String, AuthCredential) -> String
    let currentAuth: () -> AuthCredential?
    let tryRestoringPersistedUser: () -> Void
    let finalizeSignIn: (LoginData, @escaping (NSError) -> Void, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void) -> Void
    let unlockIfRememberedCredentials: (String?, () -> Void, (() -> Void)?, (() -> Void)?) -> Void
    let loginCreationClosure: LoginCreationClosure
    let shouldShowAlertOnError: Bool

    func finalizeSignIn(loginData: LoginData, onError: @escaping (NSError) -> Void,
                        reachLimit: @escaping () -> Void, existError: @escaping () -> Void, showSkeleton: @escaping () -> Void, tryUnlock: @escaping () -> Void) {
        finalizeSignIn(loginData, onError, reachLimit, existError, showSkeleton, tryUnlock)
    }
    func unlockIfRememberedCredentials(forUser: String?, requestMailboxPassword: @escaping () -> Void, unlockFailed: @escaping () -> Void, unlocked: @escaping () -> Void) {
        unlockIfRememberedCredentials(forUser, requestMailboxPassword, unlockFailed, unlocked)
    }
}

extension SignInCoordinatorEnvironment {
    static func live(services: ServiceFactory, forceUpgradeDelegate: ForceUpgradeDelegate) -> SignInCoordinatorEnvironment {
        let doh = DoHMail.default
        let apiServiceDelegate = services.get(by: UsersManager.self)
        return .init(services: services,
                     doh: doh,
                     forceUpgradeDelegate: forceUpgradeDelegate,
                     apiServiceDelegate: apiServiceDelegate,
                     mailboxPassword: services.get(by: SignInManager.self)
                        .mailboxPassword(from:auth:),
                     currentAuth: { services.get(by: UsersManager.self).firstUser?.auth },
                     tryRestoringPersistedUser: services.get(by: UsersManager.self).tryRestore,
                     finalizeSignIn: services.get(by: SignInManager.self)
                        .finalizeSignIn(loginData:onError:reachLimit:existError:showSkeleton:tryUnlock:),
                     unlockIfRememberedCredentials: services.get(by: UnlockManager.self)
                        .unlockIfRememberedCredentials(forUser:requestMailboxPassword:unlockFailed:unlocked:),
                     loginCreationClosure: { appName, minimumAccountType, signupMode, signupPasswordRestrictions, isCloseButtonAvailable in
            let signup: SignupAvailability = .available(parameters: .init(mode: signupMode, passwordRestrictions: .atLeastEightCharactersLong, summaryScreenVariant: SummaryScreenVariant.screenVariant(.mail(SummaryStartButtonText("Start using Proton Mail")))))
            let payment: PaymentsAvailability
            if UIApplication.isTestflightBeta {
                payment = .notAvailable
            } else {
                payment = .available(parameters: .init(listOfIAPIdentifiers: Constants.mailPlanIDs, listOfShownPlanNames: Constants.shownPlanNames,
                                                       reportBugAlertHandler: { receipt in
                    let link = DeepLink(.toWebSupportForm, sender: nil)
                    NotificationCenter.default.post(name: .switchView, object: link)
                }))
            }
            return LoginAndSignup(appName: appName,
                                  clientApp: .mail,
                                  doh: doh,
                                  apiServiceDelegate: apiServiceDelegate,
                                  forceUpgradeDelegate: forceUpgradeDelegate,
                                  minimumAccountType: minimumAccountType,
                                  isCloseButtonAvailable: isCloseButtonAvailable,
                                  paymentsAvailability: payment,
                                  signupAvailability: signup)
        },
                     shouldShowAlertOnError: true
        )
    }
}
