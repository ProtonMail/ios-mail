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
import ProtonCore_Services

extension PMAPIService {
    static var unauthorized: PMAPIService = {
        PMAPIService.setupTrustIfNeeded()
        let unauthorized = PMAPIService(doh: DoHMail.default, sessionUID: "")
        #if !APP_EXTENSION
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            // TODO:: fix me
            // unauthorized.authDelegate = delegate
            unauthorized.serviceDelegate = delegate
        }
        #endif
        return unauthorized
    }()

    static var shared: APIService {
        // TODO:: fix me -- shouldn't have gloabl access
        if let user = sharedServices.get(by: UsersManager.self).users.first {
            return user.apiService
        }
        // TODO: Should we have unauthorized calls here at all?
        #if !APP_EXTENSION
        self.unauthorized.humanDelegate = HumanVerificationManager.shared.humanCheckHelper(apiService: unauthorized)
        self.unauthorized.forceUpgradeDelegate = ForceUpgradeManager.shared.forceUpgradeHelper
        #endif
        return self.unauthorized
    }

    static func setupTrustIfNeeded() {
        #if DEBUG
        PMAPIService.noTrustKit = true
        #endif

        guard PMAPIService.trustKit == nil else { return }
        #if !APP_EXTENSION
        // For the extension, please check ShareExtensionEntry
        let delegate = UIApplication.shared.delegate as? AppDelegate
        TrustKitWrapper.start(delegate: delegate)
        #endif
    }
}
