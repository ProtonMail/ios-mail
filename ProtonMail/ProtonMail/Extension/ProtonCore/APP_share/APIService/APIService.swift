//
//  APIService.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import CoreData
import Foundation
import TrustKit
import ProtonCore_Authentication
import ProtonCore_Challenge
import ProtonCore_Log
import ProtonCore_Keymaker
import ProtonCore_Networking
import ProtonCore_Services

extension PMAPIService {

    private static var authManagerForUnauthorizedAPIService = AuthManagerForUnauthorizedAPIService()

    static var unauthorized: PMAPIService = {
        PMAPIService.setupTrustIfNeeded()

        let unauthorized: PMAPIService
        if let initialSessionUID = authManagerForUnauthorizedAPIService.initialSessionUID {
            unauthorized = PMAPIService.createAPIService(
                environment: BackendConfiguration.shared.environment,
                sessionUID: initialSessionUID,
                challengeParametersProvider: .forAPIService(clientApp: .mail, challenge: PMChallenge())
            )
        } else {
            unauthorized = PMAPIService.createAPIServiceWithoutSession(
                environment: BackendConfiguration.shared.environment,
                challengeParametersProvider: .forAPIService(clientApp: .mail, challenge: PMChallenge())
            )
        }
        #if !APP_EXTENSION
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            unauthorized.serviceDelegate = delegate
        }
        unauthorized.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: unauthorized)
        unauthorized.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
        #endif
        unauthorized.authDelegate = authManagerForUnauthorizedAPIService.authDelegateForUnauthorized
        return unauthorized
    }()

    static var shared: APIService {
        // TODO:: fix me -- shouldn't have gloabl access
        if let user = sharedServices.get(by: UsersManager.self).users.first {
            return user.apiService
        }
        #if !APP_EXTENSION
        self.unauthorized.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: .unauthorized)
        self.unauthorized.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
        #endif
        return self.unauthorized
    }

    static func setupTrustIfNeeded() {
//        #if DEBUG
//        PMAPIService.noTrustKit = true
//        #endif

        guard PMAPIService.trustKit == nil else { return }
        #if !APP_EXTENSION
        // For the extension, please check ShareExtensionEntry
        let delegate = UIApplication.shared.delegate as? AppDelegate
        TrustKitWrapper.start(delegate: delegate)
        #endif
    }
}

final private class AuthManagerForUnauthorizedAPIService: AuthHelperDelegate {

    private let key = "Unauthenticated_session"

    let initialSessionUID: String?

    let authDelegateForUnauthorized: AuthHelper

    init() {

        defer {
            let dispatchQueue = DispatchQueue(label: "me.proton.mail.queue.unauth-session-auth-helper-delegate")
            authDelegateForUnauthorized.setUpDelegate(self, callingItOn: .asyncExecutor(dispatchQueue: dispatchQueue))
        }

        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let data = SharedCacheBase.getDefault()?.data(forKey: key) else {
            self.authDelegateForUnauthorized = AuthHelper()
            self.initialSessionUID = nil
            return
        }

        let authlocked = Locked<[AuthCredential]>(encryptedValue: data)

        guard let authCredential = try? authlocked.unlock(with: mainKey).first else {
            SharedCacheBase.getDefault().remove(forKey: key)
            self.authDelegateForUnauthorized = AuthHelper()
            self.initialSessionUID = nil
            return
        }

        self.authDelegateForUnauthorized = AuthHelper(authCredential: authCredential)
        self.initialSessionUID = authCredential.sessionID
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential _: Credential, for _: String) {
        guard let mainKey = keymaker.mainKey(by: RandomPinProtection.randomPin),
              let lockedAuth = try? Locked<[AuthCredential]>(clearValue: [authCredential], with: mainKey) else { return }
        SharedCacheBase.getDefault()?.setValue(lockedAuth.encryptedValue, forKey: key)
    }

    func sessionWasInvalidated(for _: String, isAuthenticatedSession: Bool) {
        SharedCacheBase.getDefault()?.remove(forKey: key)
    }
}
