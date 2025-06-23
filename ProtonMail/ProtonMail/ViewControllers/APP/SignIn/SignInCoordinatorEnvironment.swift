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
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreDoh
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities
import UIKit

struct SignInCoordinatorEnvironment {
    typealias Dependencies = AuthManagerForUnauthorizedAPIService.Dependencies
    & HasSignInManager
    & HasUnlockManager
    & HasUsersManager

    typealias LoginCreationClosure =
        (String, PasswordRestrictions, Bool) -> LoginAndSignupInterface

    let apiService: APIService
    let userDefaults: UserDefaults
    let mailboxPassword: (Passphrase, AuthCredential) -> Passphrase
    let currentAuth: () -> AuthCredential?
    let tryRestoringPersistedUser: () -> Void
    let finalizeSignIn: (LoginData,
                         @escaping (NSError) -> Void,
                         () -> Void,
                         @escaping () -> Void) -> Void
    let unlockIfRememberedCredentials: (() -> Void, (() -> Void)?, (() -> Void)?) -> Void
    let loginCreationClosure: LoginCreationClosure
    let shouldShowAlertOnError: Bool
    let saveLoginData: (LoginData) -> SignInManager.LoginDataSavingResult

    func finalizeSignIn(
        loginData: LoginData,
        onError: @escaping (NSError) -> Void,
        showSkeleton: () -> Void,
        tryUnlock: @escaping () -> Void
    ) {
        finalizeSignIn(loginData, onError, showSkeleton, tryUnlock)
    }

    func unlockIfRememberedCredentials(
        requestMailboxPassword: @escaping () -> Void,
        unlockFailed: @escaping () -> Void,
        unlocked: @escaping () -> Void
    ) {
        unlockIfRememberedCredentials(requestMailboxPassword, unlockFailed, unlocked)
    }
}

extension SignInCoordinatorEnvironment {
    // swiftlint:disable function_body_length
    static func live(dependencies: Dependencies) -> SignInCoordinatorEnvironment {
        let apiService = PMAPIService.unauthorized(dependencies: dependencies)
        return .init(apiService: apiService,
                     userDefaults: dependencies.userDefaults,
                     mailboxPassword: dependencies.signInManager
                         .mailboxPassword(from:auth:),
                     currentAuth: { dependencies.usersManager.firstUser?.authCredential },
                     tryRestoringPersistedUser: dependencies.usersManager.tryRestore,
                     finalizeSignIn: dependencies.signInManager
                         .finalizeSignIn(loginData:onError:showSkeleton:tryUnlock:),
                     unlockIfRememberedCredentials: dependencies.unlockManager
                         .unlockIfRememberedCredentials(requestMailboxPassword:unlockFailed:unlocked:),
                     loginCreationClosure: { appName, passwordRestrictions, isCloseButtonAvailable in
                         let signup: SignupAvailability = .available(parameters: .init(
                             separateDomainsButton: true,
                             passwordRestrictions: passwordRestrictions,
                             summaryScreenVariant: SummaryScreenVariant.screenVariant(
                                 .mail(SummaryStartButtonText("Start using Proton Mail"))
                             )
                         ))
                         let payment: PaymentsAvailability
                         if Application.arePaymentsEnabled {
                             payment = .available(parameters: .init(
                                 listOfIAPIdentifiers: Constants.mailPlanIDs,
                                 listOfShownPlanNames: Constants.shownPlanNames,
                                 reportBugAlertHandler: { _ in
                                     let link = DeepLink(.toWebSupportForm, sender: nil)
                                     NotificationCenter.default.post(name: .switchView, object: link)
                                 }
                             ))
                         } else {
                             payment = .notAvailable
                         }
                         return LoginAndSignup(appName: appName,
                                               clientApp: .mail,
                                               apiService: apiService,
                                               minimumAccountTypes: .init(login: .external, signup: .internal),
                                               isCloseButtonAvailable: isCloseButtonAvailable,
                                               paymentsAvailability: payment,
                                               signupAvailability: signup)
                     },
                     shouldShowAlertOnError: true,
                     saveLoginData: {
            // clean up the credentials and session to have it pristine before the next login
            apiService.authDelegate?.onUnauthenticatedSessionInvalidated(sessionUID: apiService.sessionUID)
            apiService.setSessionUID(uid: "")
            return dependencies.signInManager.saveLoginData(loginData: $0)
        })
    }
}
