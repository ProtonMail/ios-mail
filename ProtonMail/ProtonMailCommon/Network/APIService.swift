//
//  APIService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import CoreData
import Foundation
import TrustKit
import ProtonCore_Services

extension PMAPIService {
    public static var unauthorized: PMAPIService = {
        let unauthorized = PMAPIService(doh: DoHMail.default, sessionUID: "")
        #if !APP_EXTENSION
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            //TODO:: fix me
            //unauthorized.authDelegate = delegate
            unauthorized.serviceDelegate = delegate
        }
        #endif
        return unauthorized
    }()
    
    
    static var shared: APIService {
        //TODO:: fix me -- shouldn't have gloabl access
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
}
