//
//  Localization+Plurals.swift
//  ProtonCore-CoreTranslation - Created on 02.02.2022
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

// swiftlint:disable line_length identifier_name

import Foundation

public extension LocalizedString {
    
    // Only plural strings should be placed here
    
    /// Plan details n users
    var _pu_plan_details_n_users: String {
        NSLocalizedString("%d users", bundle: Common.bundle, comment: "Plan details n users")
    }
    
    /// Plan details n addresses
    var _pu_plan_details_n_addresses: String {
        NSLocalizedString("%d email addresses", bundle: Common.bundle, comment: "Plan details n addresses")
    }

    /// Plan details n addresses per user
    var _pu_plan_details_n_addresses_per_user: String { NSLocalizedString("%d email addresses / user", bundle: Common.bundle, comment: "Plan details n address per user")
    }
    
    /// Plan details n calendars
    var _pu_plan_details_n_calendars: String {
        NSLocalizedString("%d calendars", bundle: Common.bundle, comment: "Plan details n calendar")
    }
    
    /// Plan details n folders / labels
    var _pu_plan_details_n_folders: String {
        NSLocalizedString("%d folders / labels", bundle: Common.bundle, comment: "Plan details n folders / labels")
    }
    
    /// Plan details n countries
    var _pu_plan_details_countries: String {
        NSLocalizedString("%d countries", bundle: Common.bundle, comment: "Plan details n countries")
    }
    
    /// Plan details n connections
    var _pu_plan_details_n_connections: String {
        NSLocalizedString("%d connections", bundle: Common.bundle, comment: "Plan details n connections")
    }
    
    /// Plan details n VPN connections
    var _pu_plan_details_n_vpn_connections: String {
        NSLocalizedString("%d VPN connections", bundle: Common.bundle, comment: "Plan details n VPN connections")
    }
    
    /// Plan details n high-speed connections
    var _pu_plan_details_n_high_speed_connections: String {
        NSLocalizedString("%d high-speed VPN connections", bundle: Common.bundle, comment: "Plan details n high-speed connections")
    }
    
    /// Plan details n custom domains
    var _pu_plan_details_n_custom_domains: String {
        NSLocalizedString("%d custom domains", bundle: Common.bundle, comment: "Plan details n custom domains")
    }
    
    /// Plan details n custom email domains
    var _new_plans_details_n_custom_email_domains: String {
        NSLocalizedString("New_Plans Support for %d custom email domains", bundle: Common.bundle, comment: "New_Plans details n custom email domains")
    }
    
    /// Plan details n folders and  labels
    var _new_plans_details_n_folders_labels: String {
        NSLocalizedString("New_Plans %d folders and labels", bundle: Common.bundle, comment: "New_Plans Plan details n folders and labels")
    }
    
    /// Plan details n personal calendars
    var _new_plans_details_n_personal_calendars: String {
        NSLocalizedString("New_Plans %d personal calendars", bundle: Common.bundle, comment: "New_Plans Plan details n personal calendars")
    }
    
    /// Plan details VPN on n devices
    var _new_plans_details_vpn_on_n_devices: String {
        NSLocalizedString("New_Plans High-speed VPN on %d devices", bundle: Common.bundle, comment: "New_Plans Plan details VPN on n devices")
    }
    
    /// Plan details VPN connections
    var _new_plans_details_vpn_servers: String {
        NSLocalizedString("New_Plans %d+ servers in %d countries", bundle: Common.bundle, comment: "New_Plans Plan details n servers in m countries")
    }
    
    /// Plan details VPN free connections
    var _new_plans_details_vpn_free_servers: String {
        NSLocalizedString("New_Plans %d servers in %d countries (US, NL, JP)", bundle: Common.bundle, comment: "New_Plans Plan details free n servers in m countries")
    }
    
    /// Plan details VPN medium speed n connections
    var _new_plans_details_vpn_free_speed_n_connections: String {
        NSLocalizedString("New_Plans Medium VPN speed %d VPN connections", bundle: Common.bundle, comment: "New_Plans Plan details free speed n VPN connections")
    }
    
    /// Plan details n of m users
    var _new_plans_details_n_of_m_users: String {
        NSLocalizedString("New_Plans %d of %d users", bundle: Common.bundle, comment: "New_Plans Plan details n of m users")
    }
    
    /// Plan details n of m addresses
    var _new_plans_details_n_of_m_addresses: String {
        NSLocalizedString("New_Plans %d of %d email addresses", bundle: Common.bundle, comment: "New_Plans Plan details n addresses")
    }
    
    /// Plan details n of m personal calendars
    var _new_plans_details_n_of_m_personal_calendars: String {
        NSLocalizedString("New_Plans %d of %d personal calendars", bundle: Common.bundle, comment: "New_Plans Plan details n of m personal calendars")
    }
    
    /// Plan details n addresses per user
    var _new_plans_details_n_addresses_per_user: String { NSLocalizedString("New_Plans %d addresses per user", bundle: Common.bundle, comment: "New_Plans Plan details n addresses per user")
    }
    
    /// Plan details n personal calendars per user
    var _new_plans_details_n_personal_calendars_per_user: String {
        NSLocalizedString("New_Plans %d personal calendars per user", bundle: Common.bundle, comment: "New_Plans Plan details n personal calendars per user")
    }
    
    /// Plan details n connections per user
    var _new_plans_details_n_connections_per_user: String {
        NSLocalizedString("New_Plans %d VPN connections per user", bundle: Common.bundle, comment: "New_Plans Plan details n connections per user")
    }
}
