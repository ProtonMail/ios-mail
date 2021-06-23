//
//  ServicePlanDetails+Extensions.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
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

import Foundation
import ProtonCore_Payments
import ProtonCore_CoreTranslation

extension ServicePlanDetails {
    var nameDescription: String {
        return name.count > 0 ? name.prefix(1).capitalized + name.dropFirst() : ""
    }
    
    var usersDescription: String {
        return maxMembers == 1 ? String(format: CoreString._pu_plan_details_n_user, maxMembers) : String(format: CoreString._pu_plan_details_n_users, maxMembers)
    }
    
    var storageDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary

        let storageText = name == AccountPlan.free.rawValue ? CoreString._pu_plan_details_free_storage : CoreString._pu_plan_details_storage
        return String(format: storageText, formatter.string(fromByteCount: Int64(maxSpace)))
    }
    
    var addressesDescription: String {
        return maxAddresses == 1 ? String(format: CoreString._pu_plan_details_n_address, maxAddresses) : String(format: CoreString._pu_plan_details_n_addresses, maxAddresses)
    }
    
    var additionalDescription: [String] {
        switch name {
        case AccountPlan.mailPlus.rawValue, AccountPlan.pro.rawValue, AccountPlan.visionary.rawValue:
            return [CoreString._pu_plan_details_unlimited_data,
                    CoreString._pu_plan_details_custom_email]
        default:
            return []
        }
    }
}
