//
//  PlanDetails.swift
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

public struct PurchasablePlanDescription {
    let name: String?
    let description: String?
    let details: [(DetailType, String)]
    let isPreferred: Bool

    public init(name: String?,
                description: String?,
                details: [(UIImage, String)],
                isPreferred: Bool) {
        self.init(name: name,
                  description: description,
                  details: details.map { image, text in (DetailType.custom(image), text) },
                  isPreferred: isPreferred)
    }

    init(name: String?,
         description: String?,
         details: [(DetailType, String)],
         isPreferred: Bool) {
        self.name = name
        self.description = description
        self.details = details
        self.isPreferred = isPreferred
    }
}

struct PlanDetails {
    
    enum Highlight: Equatable {
        case no
        case preferred
        case offer(percentage: String?, description: String)
    }
    
    let name: String
    let title: String?
    var price: String?
    let cycle: String?
    var isSelectable: Bool
    let details: [(DetailType, String)]
    var highlight: Highlight = .no
}

let percentageNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.locale = .autoupdatingCurrent
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    return formatter
}()

extension PlanDetails {
    // swiftlint:disable function_parameter_count
    static func createPlan(from details: Plan,
                           plan: InAppPurchasePlan,
                           countriesCount: Int?,
                           clientApp: ClientApp,
                           storeKitManager: StoreKitManagerProtocol,
                           customPlansDescription: CustomPlansDescription,
                           protonPrice: String?,
                           isSelectable: Bool) -> PlanDetails {
        let planDataDetails = planDataDetails(from: details, countriesCount: countriesCount, clientApp: clientApp,
                                              customPlansDescription: customPlansDescription)
        let name = planDataDetails.name ?? details.titleDescription
        let price = plan.planPrice(from: storeKitManager) ?? protonPrice
        let highlight: Highlight
        let cycle = details.cycle.map(String.init) ?? InAppPurchasePlan.defaultCycle
        if let defaultPricing = details.defaultPricing(for: cycle),
           let currentPricing = details.pricing(for: cycle),
           defaultPricing != currentPricing {
            let percentage = Double(currentPricing) / Double(defaultPricing) - 1.0
            let percentageString = percentageNumberFormatter.string(from: percentage as NSNumber)
            let description = PUITranslations.plan_limited_time_offer.l10n
            highlight = .offer(percentage: percentageString ?? nil, description: description)
        } else if planDataDetails.isPreferred {
            highlight = .preferred
        } else {
            highlight = .no
        }
        return PlanDetails(name: name,
                           title: planDataDetails.description,
                           price: price,
                           cycle: details.cycleDescription,
                           isSelectable: isSelectable,
                           details: planDataDetails.details,
                           highlight: highlight)
    }

    typealias PlanDataOptDetails = (name: String?, description: String?, optDetails: [(DetailType, String?)], isPreferred: Bool)

    // swiftlint:disable:next function_body_length
    private static func planDataDetails(
        from details: Plan, countriesCount: Int?, clientApp: ClientApp, customPlansDescription: CustomPlansDescription
    ) -> PurchasablePlanDescription {
        if let customDescription = customPlansDescription[details.name]?.purchasable {
            return customDescription
        }
        let strDetails: PlanDataOptDetails
        switch details.hashedName {
        case "383ef36928344f56ffe8fe23ceed2ad8c0db8ec222c5f56c47163747dc738a0e":
            strDetails = (name: "Plus",
                          description:
                            PUITranslations.plan_details_plus_description.l10n,
                          optDetails: [
                            (.checkmark, details.XGBStorageDescription),
                            (.checkmark, details.YAddressesDescription),
                            (.checkmark, details.plusLabelsDescription),
                            (.checkmark, details.customEmailDescription),
                            (.checkmark, details.priorityCustomerSupportDescription)
                          ],
                          isPreferred: false)

        case "3193add47e3d68efb9f1bbb968faf769c1c14707526145e517e262812aab4a58":
            strDetails = (name: "Basic",
                          description: nil,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescription(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highSpeedDescription)
                          ],
                          isPreferred: false)
            
        case "c277c92ffb58ea9aeef4d621a3cc83991c402db7a0f61b598454e34286061711":
            strDetails = (name: "Plus",
                          description: nil,
                          optDetails: [
                            (.checkmark, details.vpnPaidCountriesDescription(countries: countriesCount)),
                            (.checkmark, details.UConnectionsDescription),
                            (.checkmark, details.highestSpeedDescription),
                            (.checkmark, details.adblockerDescription),
                            (.checkmark, details.streamingServiceDescription)
                          ],
                          isPreferred: false)

        case "b1fedaf0300a6a79f73918565cc0870abffd391e3e1899ed6d602c3339e1c3bb":
            strDetails = (name: nil,
                          description: PUITranslations._plan_details_plus_description.l10n,
                          optDetails: [
                            (.storage, details.XGBStorageDescription),
                            (.envelope, details.YAddressesDescription),
                            (.globe, details.VCustomEmailDomainDescription),
                            (.tag, details.unlimitedFoldersLabelsFiltersDescription),
                            (.calendarCheckmark, details.ZCalendarsDescription),
                            (.shield, details.VPNFreeDescription)
                          ],
                          isPreferred: false)

        case "f6df8a2c854381704084384cd102951c2caa33cdcca15ab740b34569acfbfc10":
            strDetails = (name: nil,
                          description: PUITranslations._plan_details_vpn_plus_description.l10n,
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
                          description: PUITranslations._new_plan_details_drive_plus_description.l10n,
                          optDetails: [
                            (.storage, details.XGBStorageDescription),
                            (.envelope, details.YAddressesDescription),
                            (.calendarCheckmark, details.ZCalendarsDescription),
                            (.shield, details.UVPNConnectionsDescription),
                          ],
                          isPreferred: false)

        case "04567dee288f15bb533814cf89f3ab5a4fa3c25d1aed703a409672181f8a900a":
            switch clientApp {
            case .pass:
                strDetails = (name: nil,
                              description: PUITranslations._plan_details_bundle_description.l10n,
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
                              ],
                              isPreferred: true)
            default:
                strDetails = (name: nil,
                              description: PUITranslations._plan_details_bundle_description.l10n,
                              optDetails: [
                                (.storage, details.XGBStorageDescription),
                                (.envelope, details.YAddressesDescription),
                                (.globe, details.VCustomEmailDomainDescription),
                                (.tag, details.unlimitedFoldersLabelsFiltersDescription),
                                (.calendarCheckmark, details.ZCalendarsDescription),
                                (.shield, details.VPNUDevicesDescription)
                              ],
                              isPreferred: true)
            }

        case "599c124096f1f87dae3deb83b654c6198b8ecb9c150d2a4aa513c41288dd7645":
            strDetails = (name: nil,
                          description: PUITranslations._plan_pass_description.l10n,
                          optDetails: [
                            (.infinity, details.unlimitedLoginsAndNotesDescription),
                            (.infinity, details.unlimitedDevicesDescription),
                            (.vault, details.vaultsDescription(number: 20)),
                            (.alias, details.unlimitedEmailAliasesDescription),
                            (.lock, details.integrated2FADescription),
//                            (.forward, details.forwardingMailboxesDescription(number: 5)),
                            (.penSquare, details.customFieldsDescription),
                            (.eye, details.prioritySupportDescription)
                          ],
                          isPreferred: false)

        default:
            // default description, used for no plan (aka free) or for plans with unknown ID
            switch clientApp {
            case .vpn:
                strDetails = (name: "Free",
                              description: PUITranslations.plan_details_free_description.l10n,
                              optDetails: [
                                (.servers, details.VPNFreeServersDescription(countries: countriesCount)),
                                (.rocket, details.VPNFreeSpeedDescription),
                                (.eyeSlash, details.VPNNoLogsPolicy)
                              ],
                              isPreferred: false)
            case .pass:
                strDetails = (name: "Free",
                              description: PUITranslations._plan_details_free_description.l10n,
                              optDetails: [
                                (.infinity, details.unlimitedLoginsAndNotesDescription),
                                (.infinity, details.unlimitedDevicesDescription),
                                (.vault, details.vaultsDescription(number: 1)),
                                (.alias, details.numberOfEmailAliasesDescription(number: 10))
                              ],
                              isPreferred: false)
            default:
                strDetails = (name: "Free",
                              description: PUITranslations._plan_details_free_description.l10n,
                              optDetails: [
                                (.storage, details.upToXGBStorageDescription),
                                (.envelope, details.YAddressesDescription),
                                (.tag, details.freeFoldersLabelsDescription),
                                (.calendarCheckmark, details.ZCalendarsDescription),
                                (.shield, details.VPNFreeDescription)
                              ],
                              isPreferred: false)
            }
        }
        return PurchasablePlanDescription(name: strDetails.name,
                                          description: strDetails.description,
                                          details: strDetails.optDetails.compactMap { t in t.1.map { (t.0, $0) } },
                                          isPreferred: strDetails.isPreferred)
    }

}

#endif
