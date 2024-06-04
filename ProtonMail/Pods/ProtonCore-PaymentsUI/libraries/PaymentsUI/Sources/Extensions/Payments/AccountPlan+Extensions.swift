//
//  AccountPlan+Extensions.swift
//  ProtonCorePaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if os(iOS)

import Foundation
import ProtonCorePayments

public extension InAppPurchasePlan {
    func planPrice(from storeKitManager: StoreKitManagerProtocol) -> String? {
        guard let priceLabel = priceLabel(from: storeKitManager) else { return nil }
        return PriceFormatter.formatPlanPrice(price: priceLabel.value.doubleValue,
                                              locale: priceLabel.locale)
    }

    func priceLocale(from storeKitManager: StoreKitManagerProtocol) -> Locale? {
        priceLabel(from: storeKitManager)?.locale
    }

    func priceLabel(from storeKitManager: StoreKitManagerProtocol) -> (value: NSDecimalNumber, locale: Locale)? {
        guard let storeKitProductId else { return nil }
        return storeKitManager.priceLabelForProduct(storeKitProductId: storeKitProductId)
    }
}

#endif
