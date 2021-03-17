//
//  StoreKitManagerImpl.swift
//  ProtonMail - Created on 04/02/2021.
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

import Foundation
import PMCommon
import PMPayments

class StoreKitManagerImpl: StoreKitManagerDelegate, Service {
    var apiService: APIService? {
        return sharedServices.get(by: UsersManager.self).firstUser?.apiService
    }
    
    var tokenStorage: PaymentTokenStorage? {
        return nil
    }
    
    var isUnlocked: Bool {
        return UnlockManager.shared.isUnlocked()
    }
    
    var isSignedIn: Bool {
        return sharedServices.get(by: UsersManager.self).hasUsers()
    }
    
    var activeUsername: String? {
        return sharedServices.get(by: UsersManager.self).firstUser?.defaultEmail
    }
    
    var userId: String? {
        return sharedServices.get(by: UsersManager.self).firstUser?.userInfo.userId
    }
    
    var servicePlanDataService: ServicePlanDataService? {
        #if !APP_EXTENSION
            return sharedServices.get(by: UsersManager.self).firstUser?.sevicePlanService
        #else
            return nil
        #endif
    }
}
