//
//  PlanDetails.swift
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

struct PlanDetails {
    let name: String
    let title: String?
    var price: String?
    let cycle: String?
    var isSelectable: Bool
    let details: [(DetailType, String)]
    var isPreferred: Bool = false
}

extension PlanDetails {
    // swiftlint:disable function_parameter_count
    static func createPlan(from details: Plan,
                           plan: InAppPurchasePlan,
                           countriesCount: Int?,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           protonPrice: String?,
                           isSelectable: Bool) -> PlanDetails {
        let planDataDetails = planDataDetails(from: details, countriesCount: countriesCount, clientApp: clientApp)
        let name = planDataDetails.name ?? details.titleDescription
        let price = plan.planPrice(from: storeKitManager) ?? protonPrice
        return PlanDetails(name: name, title: planDataDetails.description, price: price, cycle: details.cycleDescription, isSelectable: isSelectable, details: planDataDetails.details, isPreferred: planDataDetails.isPreferred)
    }
    
    typealias PlanDataDetails = (name: String?, description: String?, details: [(DetailType, String)], isPreferred: Bool)
    typealias PlanDataOptDetails = (name: String?, description: String?, optDetails: [(DetailType, String?)], isPreferred: Bool)
    
    private static func planDataDetails(from details: Plan, countriesCount: Int?, clientApp: ClientApp) -> PlanDataDetails {
        let strDetails: PlanDataOptDetails
        switch details.hashedName {
        case "383ef36928344f56ffe8fe23ceed2ad8c0db8ec222c5f56c47163747dc738a0e":
            strDetails = (name: "Plus",
                          description:
                            CoreString._pu_plan_details_plus_description,
                          optDetails: [
                            (.checkmark, details.XGBStorageDescription),
                            (.checkmark, details.YAddressesDescription),
                            (.checkmark, details.plusLabelsDescription),
                            (.checkmark, details.customEmailDescription),
                            (.checkmark, details.prioritySupportDescription)
                          ],
                          isPreferred: false)

        case "3193add47e3d68efb9f1bbb968faf769c1c14707526145e517e262812aab4a58":
            strDetails = (name: "Basic",
                          description: nil,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescriptionV5(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highSpeedDescription)
                          ],
                          isPreferred: false)
            
        case "c277c92ffb58ea9aeef4d621a3cc83991c402db7a0f61b598454e34286061711":
            strDetails = (name: "Plus",
                          description: nil,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescriptionV5(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highestSpeedDescription),
                            (.checkmark, details.adblockerDescription),
                            (.checkmark, details.streamingServiceDescription)
                          ],
                          isPreferred: false)

        case "b1fedaf0300a6a79f73918565cc0870abffd391e3e1899ed6d602c3339e1c3bb":
            strDetails = (name: nil,
                          description: CoreString_V5._new_plans_plan_details_plus_description,
                          optDetails: [
                            (.storage, details.XGBStorageDescription),
                            (.envelope, details.YAddressesDescription),
                            (.globe, details.VCustomEmailDomainDescription),
                            (.tag, details.unlimitedFoldersLabelsFiltersDescription),
                            (.calendarCheckmark, details.ZPersonalCalendarsDescription),
                            (.shield, details.VPNFreeDescription)
                          ],
                          isPreferred: false)

        case "f6df8a2c854381704084384cd102951c2caa33cdcca15ab740b34569acfbfc10":
            strDetails = (name: nil,
                          description: CoreString_V5._new_plans_plan_details_vpn_plus_description,
                          optDetails: [
                            (.powerOff, details.UVPNConnectionsDescription),
                            (.rocket, details.VPNHighestSpeedDescription),
                            (.servers, details.VPNServersDescription(countries: countriesCount)),
                            (.shield, details.adBlockerDescription),
                            (.play, details.accessStreamingServicesDescription),
                            (.locks, details.secureCoreServersDescription),
                            (.brandTor, details.torOverVPNDescription),
                            (.arrowsSwitch, details.p2pDescription)
                          ],
                          isPreferred: false)

        case "93d6ab89dfe0ef0cadbb77402d21e1b485937d4b9cef19390b1f5d8e7876b66a":
            strDetails = (name: nil,
                          description: nil,
                          optDetails: [
                            (.storage, details.XGBStorageDescription),
                            (.envelope, details.YAddressesDescription),
                            (.calendarCheckmark, details.ZPersonalCalendarsDescription),
                            (.shield, details.UVPNConnectionsDescription),
                          ],
                          isPreferred: false)

        case "04567dee288f15bb533814cf89f3ab5a4fa3c25d1aed703a409672181f8a900a":
            strDetails = (name: nil,
                          description: CoreString_V5._new_plans_plan_details_bundle_description,
                          optDetails: [
                            (.storage, details.XGBStorageDescription),
                            (.envelope, details.YAddressesDescription),
                            (.globe, details.VCustomEmailDomainDescription),
                            (.tag, details.unlimitedFoldersLabelsFiltersDescription),
                            (.calendarCheckmark, details.ZPersonalCalendarsDescription),
                            (.shield, details.VPNUDevicesDescription)
                          ],
                          isPreferred: true)

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            switch clientApp {
            case .vpn:
                strDetails = (name: "Free",
                              description: CoreString._pu_plan_details_free_description,
                              optDetails: [
                                (.servers, details.VPNFreeServersDescription(countries: countriesCount)),
                                (.rocket, details.VPNFreeSpeedDescription),
                                (.eyeSlash, details.VPNNoLogsPolicy)
                              ],
                              isPreferred: false)
            default:
                strDetails = (name: "Free",
                              description: CoreString_V5._new_plans_plan_details_free_description,
                              optDetails: [
                                (.storage, details.upToXGBStorageDescription),
                                (.envelope, details.YAddressesDescription),
                                (.tag, details.freeFoldersLabelsDescription),
                                (.calendarCheckmark, details.ZPersonalCalendarsDescription),
                                (.shield, details.VPNFreeDescription)
                              ],
                              isPreferred: false)
            }
        }
        return (name: strDetails.name, strDetails.description, strDetails.optDetails.compactMap { t in t.1.map { (t.0, $0) } }, isPreferred: strDetails.isPreferred)
    }

}
