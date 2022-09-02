//
//  SignInCoordinatorEnvironment.swift
//  Proton Mail - Created on 30/04/2021
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_LoginUI
import ProtonCore_Networking
import ProtonCore_Services
import UIKit

struct SignInCoordinatorEnvironment {
    typealias LoginCreationClosure =
        (String, AccountType, SignupMode, SignupPasswordRestrictions, Bool) -> LoginAndSignupInterface

    let services: ServiceFactory
    let doh: DoH & ServerConfig
    let forceUpgradeDelegate: ForceUpgradeDelegate
    let apiServiceDelegate: APIServiceDelegate
    let mailboxPassword: (String, AuthCredential) -> String
    let currentAuth: () -> AuthCredential?
    let tryRestoringPersistedUser: () -> Void
    let finalizeSignIn: (LoginData,
                         @escaping (NSError) -> Void,
                         () -> Void,
                         () -> Void,
                         () -> Void,
                         @escaping () -> Void) -> Void
    let unlockIfRememberedCredentials: (String?, () -> Void, (() -> Void)?, (() -> Void)?) -> Void
    let loginCreationClosure: LoginCreationClosure
    let shouldShowAlertOnError: Bool
    let saveLoginData: (LoginData) -> SignInManager.LoginDataSavingResult

    func finalizeSignIn(
        loginData: LoginData,
        onError: @escaping (NSError) -> Void,
        reachLimit: () -> Void,
        existError: () -> Void,
        showSkeleton: () -> Void,
        tryUnlock: @escaping () -> Void
    ) {
        finalizeSignIn(loginData, onError, reachLimit, existError, showSkeleton, tryUnlock)
    }

    func unlockIfRememberedCredentials(
        forUser: String?,
        requestMailboxPassword: @escaping () -> Void,
        unlockFailed: @escaping () -> Void,
        unlocked: @escaping () -> Void
    ) {
        unlockIfRememberedCredentials(forUser, requestMailboxPassword, unlockFailed, unlocked)
    }
}

extension SignInCoordinatorEnvironment {
    // swiftlint:disable function_body_length
    static func live(
        services: ServiceFactory,
        forceUpgradeDelegate: ForceUpgradeDelegate
    ) -> SignInCoordinatorEnvironment {
        let doh = DoHMail.default
        let apiServiceDelegate = services.get(by: UsersManager.self)
        return .init(services: services,
                     doh: doh,
                     forceUpgradeDelegate: forceUpgradeDelegate,
                     apiServiceDelegate: apiServiceDelegate,
                     mailboxPassword: services.get(by: SignInManager.self)
                         .mailboxPassword(from:auth:),
                     currentAuth: { services.get(by: UsersManager.self).firstUser?.authCredential },
                     tryRestoringPersistedUser: services.get(by: UsersManager.self).tryRestore,
                     finalizeSignIn: services.get(by: SignInManager.self)
                         .finalizeSignIn(loginData:onError:reachLimit:existError:showSkeleton:tryUnlock:),
                     unlockIfRememberedCredentials: services.get(by: UnlockManager.self)
                         .unlockIfRememberedCredentials(forUser:requestMailboxPassword:unlockFailed:unlocked:),
                     loginCreationClosure: { appName, minimumAccountType, _, _, isCloseButtonAvailable in
                         let signup: SignupAvailability = .available(parameters: .init(
                             // the ability to change signup mode is temporarily disabled
//                mode: signupMode,
                             passwordRestrictions: .atLeastEightCharactersLong,
                             summaryScreenVariant: SummaryScreenVariant.screenVariant(
                                 .mail(SummaryStartButtonText("Start using Proton Mail"))
                             )
                         ))
                         let payment: PaymentsAvailability
                         if UIApplication.isTestflightBeta {
                             payment = .notAvailable
                         } else {
                             payment = .available(parameters: .init(
                                 listOfIAPIdentifiers: Constants.mailPlanIDs,
                                 listOfShownPlanNames: Constants.shownPlanNames,
                                 reportBugAlertHandler: { _ in
                                     let link = DeepLink(.toWebSupportForm, sender: nil)
                                     NotificationCenter.default.post(name: .switchView, object: link)
                                 }
                             ))
                         }
                         return LoginAndSignup(appName: appName,
                                               clientApp: .mail,
                                               doh: doh,
                                               apiServiceDelegate: apiServiceDelegate,
                                               forceUpgradeDelegate: forceUpgradeDelegate,
                                               humanVerificationVersion: .v3,
                                               minimumAccountType: minimumAccountType,
                                               isCloseButtonAvailable: isCloseButtonAvailable,
                                               paymentsAvailability: payment,
                                               signupAvailability: signup)
                     },
                     shouldShowAlertOnError: true,
                     saveLoginData: services.get(by: SignInManager.self)
                         .saveLoginData(loginData:))
    }
}
