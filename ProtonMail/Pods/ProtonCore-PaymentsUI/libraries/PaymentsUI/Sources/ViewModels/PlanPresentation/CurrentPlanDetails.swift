//
//  CurrentPlanDetails.swift
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

import ProtonCorePayments
import typealias ProtonCoreDataModel.ClientApp
import ProtonCoreUIFoundations
import UIKit

public struct CurrentPlanDescription {
    let name: String?
    let shouldShowUsedSpace: Bool
    let details: [(DetailType, String)]

    public init(name: String? = nil, shouldShowUsedSpace: Bool, details: [(UIImage, String)]) {
        self.init(name: name, shouldShowUsedSpace: shouldShowUsedSpace,
                  details: details.map { image, text in (DetailType.custom(image), text) })
    }

    init(name: String? = nil, shouldShowUsedSpace: Bool, details: [(DetailType, String)]) {
        self.name = name
        self.shouldShowUsedSpace = shouldShowUsedSpace
        self.details = details
    }
}

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
    static func createPlan(from details: Plan,
                           plan: InAppPurchasePlan,
                           servicePlan: ServicePlanDataServiceProtocol,
                           countriesCount: Int?,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           customPlansDescription: CustomPlansDescription,
                           isMultiUser: Bool,
                           protonPrice: String?,
                           hasPaymentMethods: Bool,
                           endDate: NSAttributedString?) -> CurrentPlanDetails {
        let planDetails = planDataDetails(from: details, servicePlan: servicePlan, countriesCount: countriesCount,
                                          clientApp: clientApp, customPlansDescription: customPlansDescription, isMultiUser: isMultiUser)
        let name = planDetails.name ?? details.titleDescription
        let price: String?
        if hasPaymentMethods {
            price = protonPrice
        } else if let currentPlanCycle = details.cycle.map(String.init), let iapCycle = plan.period, currentPlanCycle != iapCycle {
            price = protonPrice
        } else {
            price = plan.planPrice(from: storeKitManager) ?? protonPrice
        }

        let space = planDetailsSpace(plan: details, servicePlan: servicePlan)
        return CurrentPlanDetails(name: name, price: price, cycle: details.cycleDescription, details: planDetails.details, endDate: endDate, usedSpace: space.usedSpace, maxSpace: space.maxSpace, usedSpaceDescription: planDetails.shouldShowUsedSpace ? space.description : nil)
    }

    struct PlanDetailsSpace {
        let usedSpace: Int64
        let maxSpace: Int64
        let description: String
    }

    private static func planDetailsSpace(plan: Plan, servicePlan: ServicePlanDataServiceProtocol) -> PlanDetailsSpace {
        var usedSpace: Int64
        var maxSpace: Int64
        if let user = servicePlan.user {
            maxSpace = Int64(user.maxSpace)
            usedSpace = Int64(user.usedSpace)
        } else {
            maxSpace = plan.maxSpace
            usedSpace = servicePlan.currentSubscription?.organization?.usedSpace ?? servicePlan.currentSubscription?.usedSpace ?? 0
        }
        let description = plan.RSGBUsedStorageSpaceDescription(usedSpace: usedSpace, maxSpace: maxSpace)
        return PlanDetailsSpace(usedSpace: usedSpace, maxSpace: maxSpace, description: description)
    }

    typealias PlanDataOptDetails = (name: String?, shouldShowUsedSpace: Bool, optDetails: [(DetailType, String?)])

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private static func planDataDetails(
        from details: Plan, servicePlan: ServicePlanDataServiceProtocol, countriesCount: Int?, clientApp: ClientApp,
        customPlansDescription: CustomPlansDescription, isMultiUser: Bool
    ) -> CurrentPlanDescription {
        if let customDescription = customPlansDescription[details.name]?.current {
            return customDescription
        }
        let strDetails: PlanDataOptDetails
        let currentSubscription = servicePlan.currentSubscription
        switch details.hashedName {
        case "383ef36928344f56ffe8fe23ceed2ad8c0db8ec222c5f56c47163747dc738a0e":
            strDetails = (name: "Plus",
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.checkmark, details.XGBStorageDescription),
                            (.checkmark, details.YAddressesDescription),
                            (.checkmark, details.plusLabelsDescription),
                            (.checkmark, details.customEmailDescription),
                            (.checkmark, details.priorityCustomerSupportDescription)
                          ])

        case "3193add47e3d68efb9f1bbb968faf769c1c14707526145e517e262812aab4a58":
            strDetails = (name: "Basic",
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescription(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highSpeedDescription)
                          ])

        case "c277c92ffb58ea9aeef4d621a3cc83991c402db7a0f61b598454e34286061711":
            strDetails = (name: "Plus",
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescription(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highestSpeedDescription),
                            (.checkmark, details.adblockerDescription),
                            (.checkmark, details.streamingServiceDescription)
                          ])

        case "cd340d1a5c4151dea2fb7e52ab3f27aebf9a4135f4506d4d6e03089f066e99d2":
            strDetails = (name: "Professional",
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.checkmark, isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription),
                            (.checkmark, isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription),
                            (.checkmark, details.VCustomDomainDescription),
                            (.checkmark, details.multiUserSupportDescription)
                          ])

        case "11d40417959631d3d2420e8cd8709893c11cd7a4db737af63e8d56cfa7866f85":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.checkmark, isMultiUser ? details.XGBStorageDescription : details.XGBStoragePerUserDescription),
                            (.checkmark, isMultiUser ? details.YAddressesDescription : details.YAddressesPerUserDescription),
                            (.checkmark, details.VCustomDomainDescription),
                            (.checkmark, details.multiUserSupportDescription)
                          ])

        case "2b8644e24f72dbea9f07b372550ee4d051f02517c07db4c14dfe3ee14e6d892a":
            strDetails = (name: "Visionary",
                          shouldShowUsedSpace: true,
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
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])

        case "f6df8a2c854381704084384cd102951c2caa33cdcca15ab740b34569acfbfc10":
            strDetails = (name: nil,
                          shouldShowUsedSpace: false,
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
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])

        case "04567dee288f15bb533814cf89f3ab5a4fa3c25d1aed703a409672181f8a900a":
            switch clientApp {
            case .pass:
                strDetails = (name: nil,
                              shouldShowUsedSpace: false,
                              optDetails: [
                                (.infinity, details.unlimitedLoginsAndNotesDescription),
                                (.infinity, details.unlimitedDevicesDescription),
                                (.vault, details.vaultsDescription(number: 20)),
                                (.alias, details.unlimitedEmailAliasesDescription),
                                (.lock, details.integrated2FADescription),
//                                (.forward, details.forwardingMailboxesDescription(number: 5)),
                                (.penSquare, details.customFieldsDescription),
                                (.storage, details.XGBStorageDescription),
                                (.envelope, details.YAddressesDescription),
                                (.shield, details.VPNUDevicesDescription),
                                (.eye, details.prioritySupportDescription)
                              ])
            default:
                strDetails = (name: nil,
                              shouldShowUsedSpace: true,
                              optDetails: [
                                (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                                (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                                (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                                (.shield, details.UVPNConnectionsDescription)
                              ])
            }
        case "1fe4f100fd26c9595c13754becb070a4e9e5f9844e4fdb03312ca5a5cedeacde":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
        case "349669448939e91acc4b777fabe73559c67bd1de4362e9bb93734a1266ff34eb":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])
        case "f6b76fa97bf94acb7ca1add9302fafd370a6e29a634900239f1ea6920b05d542":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.WUsersDescription),
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZCalendarsPerUserDescription)
                          ])

        case "edec477fd23bc034218f4db7932a71540517ebb2247ccaf408d1ffbfe12c4d43":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                            (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                            (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                            (.shield, details.UVPNConnectionsDescription)
                          ])

        case "b61a62275e3d7d6d26d239cdd1eaf106a7bd8933cfc4a2f2dd25f1279663b188":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.user, details.WUsersDescription),
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZCalendarsPerUserDescription),
                            (.shield, details.UConnectionsPerUserDescription)
                          ])

        case "65b6f529cb429faa1d8ba151e7ae84c2d16c8eb484e81b28683a3a0862554607":
            strDetails = (name: nil,
                          shouldShowUsedSpace: true,
                          optDetails: [
                            (.envelope, details.YAddressesPerUserDescriptionV5),
                            (.calendarCheckmark, details.ZCalendarsPerUserDescription),
                            (.shield, details.UConnectionsPerUserDescription)
                          ])

        case "599c124096f1f87dae3deb83b654c6198b8ecb9c150d2a4aa513c41288dd7645":
            strDetails = (name: nil,
                          shouldShowUsedSpace: false,
                          optDetails: [
                            (.infinity, details.unlimitedLoginsAndNotesDescription),
                            (.infinity, details.unlimitedDevicesDescription),
                            (.vault, details.vaultsDescription(number: 20)),
                            (.alias, details.unlimitedEmailAliasesDescription),
                            (.lock, details.integrated2FADescription),
//                            (.forward, details.forwardingMailboxesDescription(number: 5)),
                            (.penSquare, details.customFieldsDescription),
                            (.eye, details.prioritySupportDescription)
                          ])

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            switch clientApp {
            case .vpn:
                strDetails = (name: "Free",
                              shouldShowUsedSpace: false,
                              optDetails: [
                                (.servers, details.VPNFreeServersDescription(countries: countriesCount)),
                                (.rocket, details.VPNFreeSpeedDescription),
                                (.eyeSlash, details.VPNNoLogsPolicy)
                              ])

            case .pass:
                strDetails = (name: "Free",
                              shouldShowUsedSpace: false,
                              optDetails: [
                                (.infinity, details.unlimitedLoginsAndNotesDescription),
                                (.infinity, details.unlimitedDevicesDescription),
                                (.vault, details.vaultsDescription(number: 1)),
                                (.alias, details.numberOfEmailAliasesDescription(number: 10))
                              ])

            default:
                strDetails = (name: "Free",
                              shouldShowUsedSpace: true,
                              optDetails: [
                                (.user, details.TWUsersDescription(usedMembers: currentSubscription?.organization?.usedMembers)),
                                (.envelope, details.PYAddressesDescription(usedAddresses: currentSubscription?.organization?.usedAddresses)),
                                (.calendarCheckmark, details.QZCalendarsDescription(usedCalendars: currentSubscription?.organization?.usedCalendars)),
                                (.shield, details.UVPNConnectionsDescription)
                              ])
            }
        }
        return CurrentPlanDescription(name: strDetails.name,
                                      shouldShowUsedSpace: strDetails.shouldShowUsedSpace,
                                      details: strDetails.optDetails.compactMap { t in t.1.map { (t.0, $0) } })
    }

}

#endif
