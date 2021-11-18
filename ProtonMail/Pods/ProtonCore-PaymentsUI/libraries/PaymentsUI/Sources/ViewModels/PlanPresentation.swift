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

struct PlanPresentation {
    let name: String
    let title: PlanTitle
    let details: [String]
    var isSelectable: Bool
    var endDate: NSAttributedString?
    let accountPlan: InAppPurchasePlan
    var storeKitProductId: String? { accountPlan.storeKitProductId }

    var isCurrentlyProcessed: Bool = false

    static var unavailableBecauseUserHasNoAccessToPlanDetails: PlanPresentation {
        PlanPresentation(name: "", title: .unavailable, details: [], isSelectable: false, endDate: nil,
                         accountPlan: InAppPurchasePlan(protonName: InAppPurchasePlan.freePlanName, listOfIAPIdentifiers: [])!)
    }
}

enum PlanTitle: Equatable {
    case price(String?)
    case current
    case unavailable
}

extension PlanPresentation {

    // swiftlint:disable function_parameter_count
    static func createPlan(from details: Plan,
                           storeKitManager: StoreKitManagerProtocol,
                           isCurrent: Bool,
                           isSelectable: Bool,
                           isMultiUser: Bool,
                           endDate: NSAttributedString?) -> PlanPresentation? {

        guard let plan = InAppPurchasePlan(protonName: details.name, listOfIAPIdentifiers: storeKitManager.inAppPurchaseIdentifiers)
        else { return nil }
        let name = details.titleDescription
        let title: PlanTitle = isCurrent == true ? .current : .price(plan.planPrice(from: storeKitManager))
        let planDetails = planDetails(from: details, isMultiUser: isMultiUser)
        return PlanPresentation(name: name, title: title, details: planDetails, isSelectable: isSelectable, endDate: endDate, accountPlan: plan)
    }

    // swiftlint:disable function_body_length
    private static func planDetails(from details: Plan, isMultiUser: Bool) -> [String] {
        let strDetails: [String?]
        switch details.iD {
        case "ziWi-ZOb28XR4sCGFCEpqQbd1FITVWYfTfKYUmV_wKKR3GsveN4HZCh9er5dhelYylEp-fhjBbUPDMHGU699fw==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.VCustomDomainDescription
            ]

        case "cjGMPrkCYMsx5VTzPkfOLwbrShoj9NnLt3518AH-DQLYcvsJwwjGOkS8u3AcnX4mVSP6DX2c6Uco99USShaigQ==":
            strDetails = [
                details.UVPNConnectionsDescription,
                details.highSpeedDescription,
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription
            ]

        case "S6oNe_lxq3GNMIMFQdAwOOk5wNYpZwGjBHFr5mTNp9aoMUaCRNsefrQt35mIg55iefE3fTq8BnyM4znqoVrAyA==":
            strDetails = [
                details.UVPNConnectionsDescription,
                details.highestSpeedDescription,
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription
            ]

        case "R0wqZrMt5moWXl_KqI7ofCVzgV0cinuz-dHPmlsDJjwoQlu6_HxXmmHx94rNJC1cNeultZoeFr7RLrQQCBaxcA==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]
            
        case "ARy95iNxhniEgYJrRrGvagmzRdnmvxCmjArhv3oZhlevziltNm07euTTWeyGQF49RxFpMqWE_ZGDXEvGV2CEkA==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]

        case "m-dPNuHcP8N4xfv6iapVg2wHifktAD1A1pFDU95qo5f14Vaw8I9gEHq-3GACk6ef3O12C3piRviy_D43Wh7xxQ==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UHighSpeedVPNConnectionsDescription,
                details.VCustomDomainDescription,
                details.WUsersDescription
            ]

        case "IQpNgbDPcAyAH5Y8nlaKYq3L9uMOW929zmZxe3Re1n5L7fdYed9HVErP1AMV8r9f-h9_Ckglrts75_6xnSMhCQ==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UVPNConnectionsDescription,
                details.VCustomDomainDescription
            ]

        case "ha0056vPzrt4ErHVbwEGSfMo-e0__HU2kvV-XfkspMOCkVKYsJ5BaD1KUXYSLcR0D7K0q6_J_Z8HgJdGGxrJRA==":
            strDetails = [
                details.UHighSpeedVPNConnectionsDescription,
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription
            ]

        case "sW6Msiby3tNWhOQycK3dOolAL341K40KHOPNv5wSVVFZwkayc7PIflVDxGU8oMwYoGVuI8RWz5OL3yomRfcO6A==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UVPNConnectionsDescription
            ]

        case "7J7smwDoOZD537x3sohypBmu8phtWjoc7NmddefXLbHy76M8iTpcU9Zn0QsZhN9tRpJ8ILZ2GZVhaeCbku4IPQ==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UVPNConnectionsDescription,
                details.VCustomDomainDescription
            ]
            
        case "Bq1saqZsuqU5bf4pfkaQWs6I1pj4-w4XWMaeYMhsF5AiU5KZw_PFUkGi8F3cPi3wcxhbsyyGMWUGkEgY7pqFjg==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]
            
        case "eV6W5eQXiEchPojDM6SPSy7ph6tkHS1U52TBoZpT_EVqKJsO8rLjHaxS2p0MV9TmugYPdato-OX_NGF-yUEa6Q==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                details.multiUserSupportDescription
            ]
            
        case "TZ0gXiJpXxhLyU2NB1ClFY1mkNISAk0vQKuLUV7MLAynE99drRWsw-7deVSaX8vhZ_Q6rCe4GHrF-9LX345S_w==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                isMultiUser ? details.UHighSpeedVPNConnectionsDescription : details.UHighSpeedVPNConnectionsPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]

        case "hkw1pXa83IP_hkXMWCR5LraS6XIxCjCeVfgiuu3Rkge7pdwFJSoGa4H_9_9-qol9f4Cee0KLNXmiNYCcBRl8Aw==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UHighSpeedVPNConnectionsDescription,
                details.VCustomDomainDescription,
                details.WUsersDescription
            ]

        case "ihu53A4CrTd3dTadqbbZOhcnoPZpT2fwUVXoO2nai2IIl9urLn9CU04d8tWtRS4mbZEZ261RkagN1J1l42K6dw==":
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesDescription,
                details.ZCalendarsDescription,
                details.UHighSpeedVPNConnectionsDescription,
                details.VCustomDomainDescription,
                details.WUsersDescription
            ]
            
        case "B78qtYLE6I1BjXKknSHfCGRBlpkWhe-QnR68jPYnO5clBmhF9AGwBlgt_mh5M9Dje4vuMdz9QyMKXVorCx0feg==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                isMultiUser ? details.UHighSpeedVPNConnectionsDescription : details.UHighSpeedVPNConnectionsPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]

        case "gi_MHe7rStGdIGADZ0zR5fqgqD4FIjq_G53NRs-2uZfiNqYLhA6YSCTX6Ho_OYEwi0v8NLUDoZFPJZouJ_YGzw==":
            strDetails = [
                isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription,
                isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription,
                isMultiUser ? details.ZCalendarsDescription : details.ZCalendarsPerUserDescription,
                isMultiUser ? details.UHighSpeedVPNConnectionsDescription : details.UHighSpeedVPNConnectionsPerUserDescription,
                details.VCustomDomainDescription,
                details.multiUserSupportDescription
            ]

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            strDetails = [
                details.XGBStorageDescription,
                details.YAddressesAndZCalendars,
                details.UVPNConnectionsDescription
            ]
        }
        return strDetails.compactMap { $0 }
    }

}
