//
//  CurrentPlanDetails.swift
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
import ProtonCore_CoreTranslation_V5
import ProtonCore_UIFoundations
import UIKit

struct CurrentPlanDetails {
    let name: String
    var price: String?
    let cycle: String?
    let details: [(DetailType, String)]
    var endDate: NSAttributedString?
    let usedSpace: Int64
    let maxSpace: Int64
    let usedSpaceDescription: String?
}

extension CurrentPlanDetails {
    // swiftlint:disable function_parameter_count
    static func createPlan(from details: Plan,
                           plan: InAppPurchasePlan,
                           currentSubscription: Subscription?,
                           countriesCount: Int?,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           isMultiUser: Bool,
                           protonPrice: String?,
                           hasPaymentMethods: Bool,
                           endDate: NSAttributedString?) -> CurrentPlanDetails {
        let planDetails = planDataDetails(from: details, currentSubscription: currentSubscription, countriesCount: countriesCount, clientApp: clientApp, isMultiUser: isMultiUser)
        let name = planDetails.name ?? details.titleDescription
        let price: String?
        if hasPaymentMethods {
            price = protonPrice
        } else if let currentPlanCycle = details.cycle.map(String.init), let iapCycle = plan.period, currentPlanCycle != iapCycle {
            price = protonPrice
        } else {
            price = plan.planPrice(from: storeKitManager) ?? protonPrice
        }
        return CurrentPlanDetails(name: name, price: price, cycle: details.cycleDescription, details: planDetails.details, endDate: endDate, usedSpace: currentSubscription?.organization?.usedSpace ?? 0, maxSpace: details.maxSpace, usedSpaceDescription: planDetails.usedSpace)
    }
    
    typealias PlanDataDetails = (name: String?, usedSpace: String?, details: [(DetailType, String)])
    typealias PlanDataOptDetails = (name: String?, usedSpace: String?, optDetails: [(DetailType, String?)])
    
    // swiftlint:disable function_body_length
    private static func planDataDetails(from details: Plan, currentSubscription: Subscription?, countriesCount: Int?, clientApp: ClientApp, isMultiUser: Bool) -> PlanDataDetails {
        let strDetails: PlanDataOptDetails
        let usedSpace = currentSubscription?.organization?.usedSpace ?? currentSubscription?.usedSpace
        switch details.hashedName {
        case "383ef36928344f56ffe8fe23ceed2ad8c0db8ec222c5f56c47163747dc738a0e":
            strDetails = (name: "Plus",
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, details.XGBStorageDescription),
                            (.checkmark, details.YAddressesDescription),
                            (.checkmark, details.plusLabelsDescription),
                            (.checkmark, details.customEmailDescription),
                            (.checkmark, details.prioritySupportDescription)
                          ])

        case "3193add47e3d68efb9f1bbb968faf769c1c14707526145e517e262812aab4a58":
            strDetails = (name: "Basic",
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescriptionV5(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highSpeedDescription)
                          ])
            
        case "c277c92ffb58ea9aeef4d621a3cc83991c402db7a0f61b598454e34286061711":
            strDetails = (name: "Plus",
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescriptionV5(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highestSpeedDescription),
                            (.checkmark, details.adblockerDescription),
                            (.checkmark, details.streamingServiceDescription)
                          ])
            
        case "cd340d1a5c4151dea2fb7e52ab3f27aebf9a4135f4506d4d6e03089f066e99d2":
            strDetails = (name: "Professional",
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription),
                            (.checkmark, isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription),
                            (.checkmark, details.VCustomDomainDescription),
                            (.checkmark, details.multiUserSupportDescription)
                          ])
            
        case "11d40417959631d3d2420e8cd8709893c11cd7a4db737af63e8d56cfa7866f85":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription),
                            (.checkmark, isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription),
                            (.checkmark, details.VCustomDomainDescription),
                            (.checkmark, details.multiUserSupportDescription)
                          ])

        case "2b8644e24f72dbea9f07b372550ee4d051f02517c07db4c14dfe3ee14e6d892a":
            strDetails = (name: "Visionary",
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.checkmark, details.XGBStorageDescription),
                            (.checkmark, details.YAddressesDescription),
                            (.checkmark, details.ZCalendarsDescription),
                            (.checkmark, details.UHighSpeedVPNConnectionsDescription),
                            (.checkmark, details.VCustomDomainDescription),
                            (.checkmark, details.WUsersDescription)
                          ])
            
        case "b1fedaf0300a6a79f73918565cc0870abffd391e3e1899ed6d602c3339e1c3bb":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])

        case "f6df8a2c854381704084384cd102951c2caa33cdcca15ab740b34569acfbfc10":
            strDetails = (name: nil,
                          usedSpace: nil,
                          optDetails: [
                            (.powerOff, details.UVPNConnectionsDescription),
                            (.rocket, details.VPNHighestSpeedDescription),
                            (.servers, details.VPNServersDescription(countries: countriesCount)),
                            (.shield, details.adBlockerDescription),
                            (.play, details.accessStreamingServicesDescription),
                            (.locks, details.secureCoreServersDescription),
                            (.brandTor, details.torOverVPNDescription),
                            (.arrowsSwitch, details.p2pDescription)
                          ])
        case "93d6ab89dfe0ef0cadbb77402d21e1b485937d4b9cef19390b1f5d8e7876b66a":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])

        case "04567dee288f15bb533814cf89f3ab5a4fa3c25d1aed703a409672181f8a900a":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
        case "1fe4f100fd26c9595c13754becb070a4e9e5f9844e4fdb03312ca5a5cedeacde":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
        case "349669448939e91acc4b777fabe73559c67bd1de4362e9bb93734a1266ff34eb":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
        case "f6b76fa97bf94acb7ca1add9302fafd370a6e29a634900239f1ea6920b05d542":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.WUsersDescription),
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZPersonalCalendarsPerUserDescription)
                          ])
            
        case "edec477fd23bc034218f4db7932a71540517ebb2247ccaf408d1ffbfe12c4d43":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
            
        case "b61a62275e3d7d6d26d239cdd1eaf106a7bd8933cfc4a2f2dd25f1279663b188":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.user, details.WUsersDescription),
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZPersonalCalendarsPerUserDescription),
                            (.shield, details.UConnectionsPerUserDescription)
                          ])
            
        case "65b6f529cb429faa1d8ba151e7ae84c2d16c8eb484e81b28683a3a0862554607":
            strDetails = (name: nil,
                          usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                          optDetails: [
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZPersonalCalendarsPerUserDescription),
                            (.shield, details.UConnectionsPerUserDescription)
                          ])

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            switch clientApp {
            case .vpn:
                strDetails = (name: "Free",
                              usedSpace: nil,
                              optDetails: [
                                (.servers, details.VPNFreeServersDescription(countries: countriesCount)),
                                (.rocket, details.VPNFreeSpeedDescription),
                                (.eyeSlash, details.VPNNoLogsPolicy)
                              ])
            default:
                strDetails = (name: "Free",
                              usedSpace: details.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace),
                              optDetails: [
                                (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                                (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                                (.calendarCheckmark, details.QZPersonalCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                                (.shield, details.UVPNConnectionsDescription)
                              ])
            }
        }
        return (name: strDetails.name, strDetails.usedSpace, strDetails.optDetails.compactMap { t in t.1.map { (t.0, $0) } })
    }

}
