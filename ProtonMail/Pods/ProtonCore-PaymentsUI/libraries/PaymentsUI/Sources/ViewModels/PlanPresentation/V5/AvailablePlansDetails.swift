//
//  AvailablePlansDetails.swift
//  ProtonCorePaymentsUI - Created on 18.08.23.
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

import UIKit
import ProtonCorePayments

struct AvailablePlansDetails {
    let iapID: String?
    let isFreePlan: Bool
    let title: String // "VPN Plus"
    let description: String? // "Your privacy are our priority."
    let cycleDescription: String? // "for 1 year"
    let defaultCycle: Int?
    let cycle: Int?
    let price: String // "$71.88"
    let decorations: [Decoration]
    let entitlements: [Entitlement]
    
    enum Decoration {
        case percentage(percentage: String)
        case offer(decription: String)
        case starred(iconName: String)
        case border(color: String)
    }
    
    struct Entitlement: Equatable {
        var text: String
        var iconUrl: URL?
        var hint: String?
    }
    
    static func createPlan(from plan: AvailablePlans.AvailablePlan,
                           for instance: AvailablePlans.AvailablePlan.Instance? = nil,
                           defaultCycle: Int?,
                           iapPlan: InAppPurchasePlan? = nil,
                           plansDataSource: PlansDataSourceProtocol?,
                           storeKitManager: StoreKitManagerProtocol? = nil) async throws -> AvailablePlansDetails? {
        let decorations: [Decoration] = plan.decorations.compactMap {
            switch $0 {
            case .border(let decoration):
                return .border(color: decoration.color)
            case .starred(let decoration):
                return .starred(iconName: decoration.iconName)
            case .badge(let badge):
                let doesPromoExist = instance?.price.first(where: { $0.ID == badge.planID }) != nil
                if doesPromoExist {
                    switch badge.anchor {
                    case .title:
                        return .percentage(percentage: badge.text)
                    case .subtitle:
                        return .offer(decription: badge.text)
                    }
                } else {
                    return nil
                }
            }
        }
        
        var entitlements = [Entitlement]()
        for entitlement in plan.entitlements {
            switch entitlement {
            case .description(let entitlement):
                entitlements.append(.init(
                    text: entitlement.text,
                    iconUrl: plansDataSource?.createIconURL(iconName: entitlement.iconName),
                    hint: entitlement.hint
                ))
            }
        }
        
        if let instance {
            guard let storeKitManager = storeKitManager,
                  let price = iapPlan?.planPrice(from: storeKitManager),
                  let iapID = instance.vendors?.apple.productID else {
                return nil
            }
            
            return .init(
                iapID: iapID,
                isFreePlan: plan.isFreePlan,
                title: plan.title,
                description: plan.description,
                cycleDescription: instance.description,
                defaultCycle: defaultCycle,
                cycle: instance.cycle,
                price: price,
                decorations: decorations,
                entitlements: entitlements
            )
        } else {
            return .init(
                iapID: nil,
                isFreePlan: plan.isFreePlan,
                title: plan.title,
                description: plan.description,
                cycleDescription: nil,
                defaultCycle: defaultCycle,
                cycle: nil,
                price: PUITranslations.plan_details_free_price.l10n,
                decorations: decorations,
                entitlements: entitlements
            )
        }
    }
}

#endif
