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
    
    /// Plan details n calendars per user
    var _pu_plan_details_n_calendars_per_user: String {
        NSLocalizedString("%d calendars / user", bundle: Common.bundle, comment: "Plan details n calendars per user")
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
    
    /// Plan details n high-speed connections per user
    var _pu_plan_details_n_high_speed_connections_per_user: String {
        NSLocalizedString("%d high-speed VPN connections / user", bundle: Common.bundle, comment: "Plan details n connections per user")
    }
    
    /// Plan details n custom domains
    var _pu_plan_details_n_custom_domains: String {
        NSLocalizedString("%d custom domains", bundle: Common.bundle, comment: "Plan details n custom domains")
    }

    /// Plan details n addresses & calendars
    var _pu_plan_details_n_addresses_and_calendars: String {
        NSLocalizedString("%d addresses & calendars", bundle: Common.bundle, comment: "Plan details n addresses & calendars")
    }
}
