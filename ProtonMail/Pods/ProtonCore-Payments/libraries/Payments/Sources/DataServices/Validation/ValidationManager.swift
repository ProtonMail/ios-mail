//
//  ValidationManager.swift
//  ProtonCore-Payments - Created on 19/03/2021.
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
import StoreKit

protocol ValidationManagerDependencies: AnyObject {
    var planService: ServicePlanDataServiceProtocol { get }
    var products: [SKProduct] { get }
}

class ValidationManager {
    unowned var dependencies: ValidationManagerDependencies

    init(dependencies: ValidationManagerDependencies) {
        self.dependencies = dependencies
    }

    func isValidPurchase(storeKitProductId: String) -> Bool {
        if case .success = canPurchaseProduct(storeKitProductId: storeKitProductId) {
            return true
        }
        return false
    }

    func canPurchaseProduct(storeKitProductId: String) -> Result<SKProduct, Error> {

        guard let product = dependencies.products.first(where: { $0.productIdentifier == storeKitProductId }) else {
            return .failure(StoreKitManager.Errors.unavailableProduct)
        }

        guard dependencies.planService.currentSubscription?.hasExistingProtonSubscription == false else {
            return .failure(StoreKitManager.Errors.invalidPurchase)
        }

        return .success(product)
    }
}
