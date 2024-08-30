//
//  SignInCoordinatorEnvironment+Dummy.swift
//  ProtonMailTests
//
//  Created by Krzysztof Siejkowski on 27/05/2021.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import Foundation
import PromiseKit
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreDoh
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices

@testable import ProtonMail

extension SignInCoordinatorEnvironment {
    static var dummyMailboxPassword: (Passphrase, AuthCredential) -> Passphrase {{ pass, _ in pass }}

    static var dummyCurrentAuth: () -> AuthCredential? {{ nil }}

    static var dummyTryRestoringPersistedUser: () -> Void {{ }}

    static var dummyFinalizeSignIn: (LoginData, @escaping (NSError) -> Void, () -> Void, @escaping () -> Void) -> Void {{ _, _, _, _ in }}

    static var dummyUnlockIfRememberedCredentials: (() -> Void, (() -> Void)?, (() -> Void)?) -> Void {{ _, _, _ in }}

    static var dummySaveLoginData: (LoginData) -> SignInManager.LoginDataSavingResult {{ _ in return .success }}

    static func test(
        login: @escaping LoginCreationClosure,
        mailboxPassword: @escaping (Passphrase, AuthCredential) -> Passphrase = dummyMailboxPassword,
        currentAuth: @escaping () -> AuthCredential? = dummyCurrentAuth,
        tryRestoringPersistedUser: @escaping () -> Void = dummyTryRestoringPersistedUser,
        finalizeSignIn: @escaping (LoginData, @escaping (NSError) -> Void, () -> Void, @escaping () -> Void) -> Void = dummyFinalizeSignIn,
        unlockIfRememberedCredentials: @escaping (() -> Void, (() -> Void)?, (() -> Void)?) -> Void = dummyUnlockIfRememberedCredentials,
        saveLoginData: @escaping (LoginData) -> SignInManager.LoginDataSavingResult = dummySaveLoginData
    ) -> SignInCoordinatorEnvironment {
        let apiMock = APIServiceMock()
        let dohMock = DohMock()
        apiMock.dohInterfaceStub.fixture = dohMock
        return .init(apiService: apiMock,
                     userDefaults: UserDefaults(),
                     mailboxPassword: mailboxPassword,
                     currentAuth: currentAuth,
                     tryRestoringPersistedUser: tryRestoringPersistedUser,
                     finalizeSignIn: finalizeSignIn,
                     unlockIfRememberedCredentials: unlockIfRememberedCredentials,
                     loginCreationClosure: login,
                     shouldShowAlertOnError: false,
                     saveLoginData: saveLoginData
        )
    }
}
