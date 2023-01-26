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
import ProtonCore_Services

extension PMAPIService {

    static var authDelegateForUnauthorized = AuthHelper()

    static var unauthorized: PMAPIService = {
        PMAPIService.setupTrustIfNeeded()
        let unauthorized = PMAPIService.createAPIServiceWithoutSession(
            doh: DoHMail.default, challengeParametersProvider: .forAPIService(clientApp: .mail, challenge: PMChallenge())
        )
        #if !APP_EXTENSION
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            unauthorized.serviceDelegate = delegate
        }
        unauthorized.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: unauthorized)
        unauthorized.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
        #endif
        // TODO: consult with Mail devs if this makes sense outside of `#if !APP_EXTENSION`
        unauthorized.authDelegate = authDelegateForUnauthorized
        // no need to handle the results in any special way, just logging for debugging purpose is enough
        unauthorized.acquireSessionIfNeeded { result in PMLog.debug("\(result)") }
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
