//
//  ServicePlanDetails+Extensions.swift
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

import Foundation
import ProtonCorePayments

extension Plan {

    /**
     Function name shortcuts:
     X = MaxSpace, converted from bytes to GB
     Y = MaxAddresses
     Z = MaxCalendars
     U = MaxVPN
     V = MaxDomains
     W = MaxMembers
     O = UsedDomains
     P = UsedAddresses
     Q = UsedCalendars
     R = UsedSpace, converted from bytes to GB
     S = AssignedSpace, converted from bytes to GB / MaxSpace on the /users API call
     T = UsedMembers
     **/

    public var titleDescription: String {
        return title
    }

    var storageformatter: StorageFormatter {
        return StorageFormatter()
    }

    var XGBStorageDescription: String {
        String(format: PUITranslations.plan_details_storage.l10n,
               storageformatter.format(value: maxSpace))
    }

    var XGBStoragePerUserDescription: String {
        return String(format: PUITranslations.plan_details_storage_per_user.l10n,
                      storageformatter.format(value: maxSpace))
    }

    var YAddressesDescription: String {
        String(format: PUITranslations.plan_details_n_addresses.l10n, maxAddresses)
    }

    var YAddressesPerUserDescription: String {
        String(format: PUITranslations.plan_details_n_addresses_per_user.l10n, maxAddresses)
    }

    var ZCalendarsDescription: String? {
        guard let maxCalendars = maxCalendars else { return nil }
        return String(format: PUITranslations.plan_details_n_calendars.l10n, maxCalendars)
    }

    var UConnectionsDescription: String {
        String(format: PUITranslations.plan_details_n_connections.l10n, maxVPN)
    }

    var UVPNConnectionsDescription: String {
        String(format: PUITranslations.plan_details_n_vpn_connections.l10n, maxVPN)
    }

    var UHighSpeedVPNConnectionsDescription: String {
        String(format: PUITranslations.plan_details_n_high_speed_connections.l10n, maxVPN)
    }

    var VCustomDomainDescription: String {
        String(format: PUITranslations.plan_details_n_custom_domains.l10n, maxDomains)
    }

    var WUsersDescription: String {
        String(format: PUITranslations.plan_details_n_users.l10n, maxMembers)
    }

    var plusLabelsDescription: String {
        return String(format: PUITranslations.plan_details_n_folders.l10n, 200)
    }

    var customEmailDescription: String {
        return PUITranslations.plan_details_custom_email.l10n
    }

    var priorityCustomerSupportDescription: String {
        return PUITranslations.plan_details_priority_support.l10n
    }

    var highSpeedDescription: String {
        PUITranslations.plan_details_high_speed.l10n
    }

    var highestSpeedDescription: String {
        PUITranslations.plan_details_highest_speed.l10n
    }

    var multiUserSupportDescription: String {
        PUITranslations.plan_details_multi_user_support.l10n
    }

    var adblockerDescription: String {
        PUITranslations.plan_details_adblocker.l10n
    }

    var streamingServiceDescription: String {
        PUITranslations.plan_details_streaming_service.l10n
    }

    var cycleDescription: String? {
        guard let cycle = cycle, cycle > 0 else { return nil }
        let dateComponents = DateComponents(month: cycle)
        let cycleString: String?
        if cycle % 12 == 0 {
            cycleString = yearsFormatter.string(from: dateComponents)
        } else {
            cycleString = monthsFormatter.string(from: dateComponents)
        }
        guard let cycleString = cycleString else { return nil }
        return String(format: PUITranslations.plan_details_price_time_period_no_unit.l10n, cycleString)
    }

    var upToXGBStorageDescription: String {
        String(format: PUITranslations._details_up_to_storage.l10n,
                      storageformatter.format(value: maxRewardsSpace ?? maxSpace))
    }

    var VCustomEmailDomainDescription: String {
        String(format: PUITranslations._details_n_custom_email_domains.l10n, maxDomains)
    }

    var unlimitedFoldersLabelsFiltersDescription: String {
        PUITranslations._details_unlimited_folders_labels_filters.l10n
    }

    var freeFoldersLabelsDescription: String {
        String(format: PUITranslations._details_n_folders_labels.l10n, 3)
    }

    var VPNFreeDescription: String {
        PUITranslations._details_vpn_on_single_device.l10n
    }

    var VPNUDevicesDescription: String {
        String(format: PUITranslations._details_vpn_on_n_devices.l10n, maxVPN)
    }

    var VPNHighestSpeedDescription: String {
        PUITranslations._details_highest_VPN_speed.l10n
    }

    func VPNServersDescription(countries: Int?) -> String {
        let countries = countries ?? 63
        return String(format: PUITranslations._details_vpn_servers.l10n, 1500, countries)
    }

    func VPNFreeServersDescription(countries: Int?) -> String {
        let countries = countries ?? 3
        return String(format: PUITranslations._details_vpn_free_servers.l10n, 24, countries)
    }

    var VPNFreeSpeedDescription: String {
        String(format: PUITranslations._details_vpn_free_speed_n_connections.l10n, maxVPN)
    }

    var VPNNoLogsPolicy: String {
        PUITranslations._details_no_logs_policy.l10n
    }

    var adBlockerDescription: String {
        PUITranslations._detailsblocker.l10n
    }

    var accessStreamingServicesDescription: String {
        PUITranslations._details_access_streaming_services.l10n
    }

    var secureCoreServersDescription: String {
        PUITranslations._details_secure_core_servers.l10n
    }

    var torOverVPNDescription: String {
        PUITranslations._details_tor_over_vpn.l10n
    }

    var p2pDescription: String {
        PUITranslations._details_p2p.l10n
    }

    func RSGBUsedStorageSpaceDescription(usedSpace: Int64, maxSpace: Int64) -> String {
        String(format: PUITranslations._details_used_storage_space.l10n,
               storageformatter.format(value: usedSpace), storageformatter.format(value: maxSpace))
    }

    func TWUsersDescription(usedMembers: Int?) -> String {
        guard let usedMembers = usedMembers, maxMembers > 1 else {
            return WUsersDescription
        }
        return String(format: PUITranslations._details_n_of_m_users.l10n, usedMembers, maxMembers)
    }

    func PYAddressesDescription(usedAddresses: Int?) -> String {
        guard let usedAddresses = usedAddresses, maxAddresses > 1 else {
            return YAddressesDescription
        }
        // avoid showing usedAddresses == 0
        let usedAddr = usedAddresses > 0 ? usedAddresses : 1
        return String(format: PUITranslations._details_n_of_m_addresses.l10n, usedAddr, maxAddresses)
    }

    func QZCalendarsDescription(usedCalendars: Int?) -> String? {
        let maxCalendars = maxCalendars ?? 0
        guard let usedCalendars = usedCalendars, maxCalendars > 1 else {
            return ZCalendarsDescription
        }
        return String(format: PUITranslations._details_n_of_m_calendars.l10n, usedCalendars, maxCalendars)
    }

    var YAddressesPerUserDescriptionV5: String {
        return String(format: PUITranslations._details_n_addresses_per_user.l10n, maxMembers > 0 ? maxAddresses / maxMembers : maxAddresses)
    }

    var ZCalendarsPerUserDescription: String {
        let maxCalendars = maxCalendars ?? 0
        return String(format: PUITranslations._details_n_calendars_per_user.l10n, maxCalendars)
    }

    var UConnectionsPerUserDescription: String {
        String(format: PUITranslations._details_n_connections_per_user.l10n, maxMembers > 0 ? maxVPN / maxMembers : maxVPN)
    }

    func vpnPaidCountriesDescription(countries: Int?) -> String {
        let countries = countries ?? 63
        return String(format: PUITranslations.plan_details_countries.l10n, countries)
    }

    var unlimitedLoginsAndNotesDescription: String {
        PUITranslations._plan_details_logins_and_notes_unlimited.l10n
    }

    var unlimitedDevicesDescription: String {
        PUITranslations._plan_details_devices_unlimited.l10n
    }

    func vaultsDescription(number: Int) -> String {
        String(format: PUITranslations._plan_details_n_vaults.l10n, number)
    }

    var unlimitedEmailAliasesDescription: String {
        PUITranslations._plan_details_email_aliases_unlimited.l10n
    }

    var integrated2FADescription: String {
        PUITranslations._plan_details_2fa_authenticator.l10n
    }

    func forwardingMailboxesDescription(number: Int) -> String {
        String(format: PUITranslations._plan_details_forwarding_mailboxes.l10n, number)
    }

    var customFieldsDescription: String {
        PUITranslations._plan_details_custom_fields.l10n
    }

    var prioritySupportDescription: String {
        PUITranslations._plan_details_priority_support.l10n
    }

    func numberOfEmailAliasesDescription(number: Int) -> String {
        String(format: PUITranslations._plan_details_email_aliases_number.l10n, number)
    }

}

private let monthsFormatter: DateComponentsFormatter = createSingleUnitFormatter(unit: .month)

private let yearsFormatter: DateComponentsFormatter = createSingleUnitFormatter(unit: .year)

private func createSingleUnitFormatter(unit: NSCalendar.Unit) -> DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = unit
    formatter.allowsFractionalUnits = false
    formatter.collapsesLargestUnit = true
    formatter.maximumUnitCount = 1
    formatter.zeroFormattingBehavior = .dropAll
    formatter.unitsStyle = .full
    return formatter
}

#endif
