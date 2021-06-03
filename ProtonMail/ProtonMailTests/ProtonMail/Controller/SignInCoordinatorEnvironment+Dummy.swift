//
//  SignInCoordinatorEnvironment+Dummy.swift
//  ProtonMailTests
//
//  Created by Krzysztof Siejkowski on 27/05/2021.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit

@testable import ProtonMail

extension SignInCoordinatorEnvironment {

    static var dummyFetchSettings: (UserInfo, AuthCredential) -> Promise<UserInfo> {{ _, _ in
        struct TestError: Error {}
        return .init(error: TestError())
    }}

    static var dummyMailboxPassword: (String, AuthCredential) -> String {{ pass, _ in pass }}

    static var dummyCurrentAuth: () -> AuthCredential? {{ nil }}

    static var dummyTryRestoringPersistedUser: () -> Void {{ }}

    static var dummyFinalizeSignIn: (UserInfo, AuthCredential, @escaping (NSError) -> Void, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void) -> Void {{ _, _, _, _, _, _ in }}

    static var dummyUnlockIfRememberedCredentials: (String?, () -> Void, (() -> Void)?, (() -> Void)?) -> Void {{ _, _, _, _ in }}

    static func test(
        login: @escaping LoginCreationClosure,
        fetchSettings: @escaping (UserInfo, AuthCredential) -> Promise<UserInfo> = dummyFetchSettings,
        mailboxPassword: @escaping (String, AuthCredential) -> String = dummyMailboxPassword,
        currentAuth: @escaping () -> AuthCredential? = dummyCurrentAuth,
        tryRestoringPersistedUser: @escaping () -> Void = dummyTryRestoringPersistedUser,
        finalizeSignIn: @escaping (UserInfo, AuthCredential, @escaping (NSError) -> Void, @escaping () -> Void, @escaping () -> Void, @escaping () -> Void) -> Void = dummyFinalizeSignIn,
        unlockIfRememberedCredentials: @escaping (String?, () -> Void, (() -> Void)?, (() -> Void)?) -> Void = dummyUnlockIfRememberedCredentials
    ) -> SignInCoordinatorEnvironment {
        .init(services: ServiceFactory(),
              doh: try! DohMock(),
              forceUpgradeDelegate: ForceUpgradeDelegateMock(),
              apiServiceDelegate: APIServiceDelegateMock(),
              fetchSettings: fetchSettings,
              mailboxPassword: mailboxPassword,
              currentAuth: currentAuth,
              tryRestoringPersistedUser: tryRestoringPersistedUser,
              finalizeSignIn: finalizeSignIn,
              unlockIfRememberedCredentials: unlockIfRememberedCredentials,
              loginCreationClosure: login,
              shouldShowAlertOnError: false
        )
    }
}
