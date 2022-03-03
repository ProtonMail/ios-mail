//
//  AccountPlan+Extensions.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Payments

extension InAppPurchasePlan {
    func planPrice(from storeKitManager: StoreKitManagerProtocol) -> String? {
        guard let storeKitProductId = storeKitProductId,
              let price = storeKitManager.priceLabelForProduct(storeKitProductId: storeKitProductId)
        else { return nil }
        return InAppPurchasePlan.formatPlanPrice(price: price.0, locale: price.1)
    }
    
    func planLocale(from storeKitManager: StoreKitManagerProtocol) -> Locale? {
        guard let storeKitProductId = storeKitProductId,
              let price = storeKitManager.priceLabelForProduct(storeKitProductId: storeKitProductId)
        else { return nil }
        return price.1
    }
    
    static func formatPlanPrice(price: NSDecimalNumber, locale: Locale, maximumFractionDigits: Int = 2) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = maximumFractionDigits
        let total = price as Decimal
        let priceString = formatter.string(from: total as NSNumber) ?? ""
        return priceString
    }
}
