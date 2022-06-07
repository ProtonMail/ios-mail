//
//  ServicePlanDetails+Extensions.swift
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

import Foundation
import ProtonCore_Payments
import ProtonCore_CoreTranslation
import ProtonCore_CoreTranslation_V5

extension Plan {

    var upToXGBStorageDescription: String {
        String(format: CoreString_V5._new_plans_details_up_to_storage,
                      storageformatter.format(value: maxRewardsSpace ?? maxSpace))
    }

    var VCustomEmailDomainDescription: String {
        String(format: CoreString_V5._new_plans_details_n_custom_email_domains, maxDomains)
    }
    
    var unlimitedFoldersLabelsFiltersDescription: String {
        CoreString_V5._new_plans_details_unlimited_folders_labels_filters
    }
    
    var freeFoldersLabelsDescription: String {
        String(format: CoreString_V5._new_plans_details_n_folders_labels, 3)
    }
    
    var ZPersonalCalendarsDescription: String? {
        guard let maxCalendars = maxCalendars else { return nil }
        return String(format: CoreString_V5._new_plans_details_n_personal_calendars, maxCalendars)
    }

    var VPNFreeDescription: String {
        CoreString_V5._new_plans_details_vpn_on_single_device
    }
    
    var VPNUDevicesDescription: String {
        String(format: CoreString_V5._new_plans_details_vpn_on_n_devices, maxVPN)
    }
    
    var VPNHighestSpeedDescription: String {
        CoreString_V5._new_plans_details_highest_VPN_speed
    }
    
    func VPNServersDescription(countries: Int?) -> String {
        let countries = countries ?? 63
        return String(format: CoreString_V5._new_plans_details_vpn_servers, 1500, countries)
    }
    
    func VPNFreeServersDescription(countries: Int?) -> String {
        let countries = countries ?? 3
        return String(format: CoreString_V5._new_plans_details_vpn_free_servers, 24, countries)
    }
    
    var VPNFreeSpeedDescription: String {
        String(format: CoreString_V5._new_plans_details_vpn_free_speed_n_connections, maxVPN)
    }
    
    var VPNNoLogsPolicy: String {
        CoreString_V5._new_plans_details_no_logs_policy
    }
    
    var adBlockerDescription: String {
        CoreString_V5._new_plans_details_ad_blocker
    }
    
    var accessStreamingServicesDescription: String {
        CoreString_V5._new_plans_details_access_streaming_services
    }
    
    var secureCoreServersDescription: String {
        CoreString_V5._new_plans_details_secure_core_servers
    }
    
    var torOverVPNDescription: String {
        CoreString_V5._new_plans_details_tor_over_vpn
    }

    var p2pDescription: String {
        CoreString_V5._new_plans_details_p2p
    }

    func RSGBUsedStorageSpaceDescription(usedSpace: Int64?) -> String {
        String(format: CoreString_V5._new_plans_details_used_storage_space,
               storageformatter.format(value: usedSpace ?? 0), storageformatter.format(value: maxSpace))
    }

    func TWUsersDescription(usedMembers: Int?) -> String {
        guard let usedMembers = usedMembers, maxMembers > 1 else {
            return WUsersDescription
        }
        return String(format: CoreString_V5._new_plans_details_n_of_m_users, usedMembers, maxMembers)
    }
    
    func PYAddressesDescription(usedAddresses: Int?) -> String {
        guard let usedAddresses = usedAddresses, maxAddresses > 1 else {
            return YAddressesDescription
        }
        // avoid showing usedAddresses == 0
        let usedAddr = usedAddresses > 0 ? usedAddresses : 1
        return String(format: CoreString_V5._new_plans_details_n_of_m_addresses, usedAddr, maxAddresses)
    }
    
    func QZPersonalCalendarsDescription(usedCalendars: Int?) -> String? {
        let maxCalendars = maxCalendars ?? 0
        guard let usedCalendars = usedCalendars, maxCalendars > 1 else {
            return ZPersonalCalendarsDescription
        }
        return String(format: CoreString_V5._new_plans_details_n_of_m_personal_calendars, usedCalendars, maxCalendars)
    }
    
    var YAddressesPerUserDescriptionV5: String {
        return String(format: CoreString_V5._new_plans_details_n_addresses_per_user, maxMembers > 0 ? maxAddresses / maxMembers : maxAddresses)
    }
    
    var ZPersonalCalendarsPerUserDescription: String {
        let maxCalendars = maxCalendars ?? 0
        return String(format: CoreString_V5._new_plans_details_n_personal_calendars_per_user, maxCalendars)
    }
    
    var UConnectionsPerUserDescription: String {
        String(format: CoreString_V5._new_plans_details_n_connections_per_user, maxMembers > 0 ? maxVPN / maxMembers : maxVPN)
    }
    
    func vpnPaidCountriesDescriptionV5(countries: Int?) -> String {
        let countries = countries ?? 63
        return String(format: CoreString._pu_plan_details_countries, countries)
    }
}
