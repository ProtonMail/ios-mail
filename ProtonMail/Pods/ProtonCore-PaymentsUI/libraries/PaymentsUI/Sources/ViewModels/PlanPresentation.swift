//
//  PlanPresentation.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
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

import ProtonCore_Payments
import typealias ProtonCore_DataModel.ClientApp
import ProtonCore_CoreTranslation

struct PlanPresentation {
    let name: String
    let title: PlanTitle
    var price: String?
    let details: [String]
    var isSelectable: Bool
    var endDate: NSAttributedString?
    let cycle: String?
    let accountPlan: InAppPurchasePlan
    var storeKitProductId: String? { accountPlan.storeKitProductId }

    var isCurrentlyProcessed: Bool = false

    static var unavailableBecauseUserHasNoAccessToPlanDetails: PlanPresentation {
        PlanPresentation(name: "", title: .unavailable, price: nil, details: [], isSelectable: false, endDate: nil, cycle: nil,
                         accountPlan: InAppPurchasePlan(protonName: InAppPurchasePlan.freePlanName, listOfIAPIdentifiers: [])!)
    }
}

enum PlanTitle: Equatable {
    case description(String?)
    case current
    case unavailable
}

extension PlanPresentation {

    // swiftlint:disable function_parameter_count
    static func createPlan(from details: Plan,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           isCurrent: Bool,
                           isSelectable: Bool,
                           isMultiUser: Bool,
                           hasPaymentMethods: Bool,
                           endDate: NSAttributedString?,
                           price protonPrice: String?) -> PlanPresentation? {
        guard let plan = InAppPurchasePlan(protonName: details.name,
                                           listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers)
        else { return nil }
        let price: String?
        if isCurrent, hasPaymentMethods {
            price = protonPrice
        } else if isCurrent, let currentPlanCycle = details.cycle.map(String.init), let iapCycle = plan.period, currentPlanCycle != iapCycle {
            price = protonPrice
        } else {
            price = plan.planPrice(from: storeKitManager) ?? protonPrice
        }
        let planDetails = planDetails(from: details, clientApp: clientApp, isMultiUser: isMultiUser)
        let name = planDetails.name ?? details.titleDescription
        let title: PlanTitle = isCurrent == true ? .current : .description(planDetails.description)
        return PlanPresentation(name: name, title: title, price: price, details: planDetails.details, isSelectable: isSelectable, endDate: endDate, cycle: details.cycleDescription, accountPlan: plan)
    }
    
    static func getLocale(from name: String, storeKitManager: StoreKitManagerProtocol) -> Locale? {
        guard let plan = InAppPurchasePlan(protonName: name, listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers) else { return nil }
        return plan.planLocale(from: storeKitManager)
    }
    
    typealias PlanDetails = (name: String?, description: String?, details: [String])
    typealias PlanOptDetails = (name: String?, description: String?, optDetails: [String?])
    // swiftlint:disable function_body_length
    private static func planDetails(from details: Plan, clientApp: ClientApp, isMultiUser: Bool) -> PlanDetails {
        let strDetails: PlanOptDetails
        switch details.hashedName {
        case "383ef36928344f56ffe8fe23ceed2ad8c0db8ec222c5f56c47163747dc738a0e":
            strDetails = (name: "Plus",
                          description:
                            CoreString._pu_plan_details_plus_description,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.plusLabelsDescription,
                            details.customEmailDescription,
                            details.prioritySupportDescription
                          ])

        case "3193add47e3d68efb9f1bbb968faf769c1c14707526145e517e262812aab4a58":
            strDetails = (name: "Basic",
                          description: nil,
                          optDetails: [
                            details.vpnPaidCountriesDescription,
                            details.UConnectionsDescription,
                            details.highSpeedDescription
                          ])
            
        case "c277c92ffb58ea9aeef4d621a3cc83991c402db7a0f61b598454e34286061711":
            strDetails = (name: "Plus",
                          description: nil,
                          optDetails: [
                            details.vpnPaidCountriesDescription,
                            details.UConnectionsDescription,
                            details.highestSpeedDescription,
                            details.adblockerDescription,
                            details.streamingServiceDescription
                          ])
            
        case "cd340d1a5c4151dea2fb7e52ab3f27aebf9a4135f4506d4d6e03089f066e99d2":
            strDetails = (name: "Professional",
                          description: CoreString._pu_plan_details_pro_description,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "11d40417959631d3d2420e8cd8709893c11cd7a4db737af63e8d56cfa7866f85":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])

        case "2b8644e24f72dbea9f07b372550ee4d051f02517c07db4c14dfe3ee14e6d892a":
            strDetails = (name: "Visionary",
                          description: CoreString._pu_plan_details_visionary_description,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UHighSpeedVPNConnectionsDescription,
                            details.VCustomDomainDescription,
                            details.WUsersDescription
                          ])

        case "b1fedaf0300a6a79f73918565cc0870abffd391e3e1899ed6d602c3339e1c3bb":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription,
                            details.VCustomDomainDescription
                          ])

        case "f6df8a2c854381704084384cd102951c2caa33cdcca15ab740b34569acfbfc10":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.UHighSpeedVPNConnectionsDescription,
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription
                          ])

        case "93d6ab89dfe0ef0cadbb77402d21e1b485937d4b9cef19390b1f5d8e7876b66a":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription
                          ])

        case "04567dee288f15bb533814cf89f3ab5a4fa3c25d1aed703a409672181f8a900a":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription,
                            details.VCustomDomainDescription
                          ])
            
        case "f6b76fa97bf94acb7ca1add9302fafd370a6e29a634900239f1ea6920b05d542":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "edec477fd23bc034218f4db7932a71540517ebb2247ccaf408d1ffbfe12c4d43":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "b61a62275e3d7d6d26d239cdd1eaf106a7bd8933cfc4a2f2dd25f1279663b188":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                            isMultiUser ? details.UHighSpeedVPNConnectionsDescription : details.UHighSpeedVPNConnectionsPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])

        case "1fe4f100fd26c9595c13754becb070a4e9e5f9844e4fdb03312ca5a5cedeacde":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UHighSpeedVPNConnectionsDescription,
                            details.VCustomDomainDescription,
                            details.WUsersDescription
                          ])

        case "349669448939e91acc4b777fabe73559c67bd1de4362e9bb93734a1266ff34eb":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UHighSpeedVPNConnectionsDescription,
                            details.VCustomDomainDescription,
                            details.WUsersDescription
                          ])
            
        case "65b6f529cb429faa1d8ba151e7ae84c2d16c8eb484e81b28683a3a0862554607":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                            isMultiUser ? details.UHighSpeedVPNConnectionsDescription : details.UHighSpeedVPNConnectionsPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            switch clientApp {
            case .vpn:
                strDetails = (name: "Free",
                              description: CoreString._pu_plan_details_free_description,
                              optDetails: [
                                details.vpnFreeCountriesDescription,
                                details.UConnectionsDescription,
                                details.vpnFreeSppedDescription
                              ])
            default:
                strDetails = (name: "Free",
                              description: CoreString._pu_plan_details_free_description,
                              optDetails: [
                                details.XGBStorageDescription,
                                details.YAddressesDescription,
                                details.freeLabelsDescription
                              ])
            }
        }
        return (name: strDetails.name, strDetails.description, strDetails.optDetails.compactMap { $0 })
    }

}
