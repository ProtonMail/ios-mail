//
//  PlanPresentation.swift
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
        switch details.iD {
        case "ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw==":
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

        case "cjGMPrkCYMsx5VTzPkfOLwbrShoj9NnLt3518AH-DQLYcvsJwwjGOkS8u3AcnX4mVSP6DX2c6Uco99USShaigQ==":
            strDetails = (name: "Basic",
                          description: nil,
                          optDetails: [
                            details.vpnPaidCountriesDescription,
                            details.UConnectionsDescription,
                            details.highSpeedDescription
                          ])
            
        case "S6oNe_lxq3GNMIMFQdAwOOk5wNYpZwGjBHFr5mTNp9aoMUaCRNsefrQt35mIg55iefE3fTq8BnyM4znqoVrAyA==":
            strDetails = (name: "Plus",
                          description: nil,
                          optDetails: [
                            details.vpnPaidCountriesDescription,
                            details.UConnectionsDescription,
                            details.highestSpeedDescription,
                            details.adblockerDescription,
                            details.streamingServiceDescription
                          ])
            
        case "R0wqZrMt5moWXl_KqI7ofCVzgV0cinuz-dHPmlsDJjwoQlu6_HxXmmHx94rNJC1cNeultZoeFr7RLrQQCBaxcA==":
            strDetails = (name: "Professional",
                          description: CoreString._pu_plan_details_pro_description,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "ARy95iNxhniEgYJrRrGvagmzRdnmvxCmjArhv3oZhlevziltNm07euTTWeyGQF49RxFpMqWE_ZGDXEvGV2CEkA==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])

        case "m-dPNuHcP8N4xfv6iapVg2wHifktAD1A1pFDU95qo5f14Vaw8I9gEHq-3GACk6ef3O12C3piRviy_D43Wh7xxQ==":
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

        case "fEZ6naOcmw7obzRd1UVIgN3yaXUKH9SgfoC8Jj_4n2q1uTq1rES78h_eaO3RHAHZ4T5vgnpAi24hgWq0QZhk8g==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription,
                            details.VCustomDomainDescription
                          ])

        case "r-cumUipwfofNYhXQWTf36Q9FBpFBdd--ZaLoGLeNGzTpKo86_yqCYWNETc4EubgVm-hgHEqbfae-t4Lw6MJSg==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.UHighSpeedVPNConnectionsDescription,
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription
                          ])

        case "38pKeB043dpMLfF_hjmZb7Zq3Gzrx6vpgojF5tPHKhJXNGUmwvNMKTSMYHDsp8Y-n8EUqYem3QMvUQh7LZDnaw==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription
                          ])

        case "KLMoowYF45_Q0hRhQ_bFx11rMIBCm3Ljr_d-U_eDQhbHSf5-j6Q2CPZxffw37BOel8uOoM0ouUmiO301xt_q7w==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            details.XGBStorageDescription,
                            details.YAddressesDescription,
                            details.ZCalendarsDescription,
                            details.UVPNConnectionsDescription,
                            details.VCustomDomainDescription
                          ])
            
        case "jctxnoKsvmlISYpOtESCWNC4tcFbddXmcQ6yyM94YP4tBngrw4O9IKf8jxSLThqZyqFlX972kKwQCPriEeh4qg==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                            isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                            details.VCustomDomainDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "Z33WkziHqmXCEJ1Udm8f2vC3Jss9EIkFrgk4_rlSDoVHASjAemj5FsCUTYr7_27bgrbE4whe41PY4TiIr9Z-TA==":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                            details.multiUserSupportDescription
                          ])
            
        case "Zv2tcvM2nlQ8XiYwWvWtfR-wO9BHprBVm-UxtpNUMlex0M-EEQpfQxdx-dEYscubmbHjMo6ItsHNp0QqTM89oA==":
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

        case "N63r9gPcEBu6cenKrOIjIwPLzuT_So458WgbiBvHbDueZ8K_PQboKAAWu5yH95-3SEk7R4nnxqlU-qhRD07r5w==":
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

        case "Ik65N-aChBuWFdo1JpmHJB4iWetfzjVLNILERQqbYFBZc5crnxOabXKuIMKhiwBNwiuogItetAUvkFTwJFJPQg==":
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
            
        case "OYB-3pMQQA2Z2Qnp5s5nIvTVO2alU6h82EGLXYHn1mpbsRvE7UfyAHbt0_EilRjxhx9DCAUM9uXfM2ZUFjzPXw==":
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
