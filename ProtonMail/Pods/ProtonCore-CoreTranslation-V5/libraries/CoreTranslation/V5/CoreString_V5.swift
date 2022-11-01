//
//  Localization.swift
//  ProtonCore-CoreTranslation - Created on 07.11.2020
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

public var CoreString_V5 = LocalizedString_V5()

public class LocalizedString_V5 {
    
    public class func reset() {
        CoreString_V5 = LocalizedString_V5()
    }
    
    // Login / Signup
    
    // Welcome screen footer
    public lazy var _ls_welcome_footer = NSLocalizedString("Privacy by default", bundle: Common_V5.bundle, comment: "Welcome screen footer label")

    // New_Plans
    
    /// Select a plan description
    public lazy var _new_plans_select_plan_description = NSLocalizedString("New_Plans One plan for all Proton services", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan selection title")
    
    /// Details free plan description
    public lazy var _new_plans_plan_details_free_description = NSLocalizedString("New_Plans The no-cost starter account designed to empower everyone with privacy by default.", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details free description")
    
    /// Details plus plan description
    public lazy var _new_plans_plan_details_plus_description = NSLocalizedString("New_Plans The privacy-first email and calendar solution for your everyday communication needs.", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details plus description")
    
    /// Details vpn plus plan description
    public lazy var _new_plans_plan_details_vpn_plus_description = NSLocalizedString("New_Plans Your privacy and security are our priority.", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details vpn plus description")
    
    /// Details bundle plan description
    public lazy var _new_plans_plan_details_bundle_description = NSLocalizedString("New_Plans The ultimate privacy pack with access to all premium Proton services.", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details bundle description")
    
    /// Plan footer description
    public lazy var _new_plans_plan_footer_desc = NSLocalizedString("New_Plans Only non-renewing annual subscriptions are available via this app", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan footer description")
    
    /// Plan details unlimited folders labels filters
    public lazy var _new_plans_details_unlimited_folders_labels_filters = NSLocalizedString("New_Plans Unlimited folders, labels, and filters", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details unlimited folders, labels, filters")
    
    /// Plan details up to storage
    public lazy var _new_plans_details_up_to_storage = NSLocalizedString("New_Plans Up to %@ storage", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details up to storage")
    
    /// Plan details VPN on a single device
    public lazy var _new_plans_details_vpn_on_single_device = NSLocalizedString("New_Plans Free VPN on a single device", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details VPN on a single device")
    
    /// Plan details Highest VPN speed
    public lazy var _new_plans_details_highest_VPN_speed = NSLocalizedString("New_Plans Highest VPN speed", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details Highest VPN speed")
    
    /// Plan details ad-blocker
    public lazy var _new_plans_details_ad_blocker = NSLocalizedString("New_Plans Built-in ad-blocker (NetShield)", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details ad-blocker")
    
    /// Plan details access to streaming services globally
    public lazy var _new_plans_details_access_streaming_services = NSLocalizedString("New_Plans Access to streaming services globally", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details Access to streaming services globally")
    
    /// Plan details secure core servers
    public lazy var _new_plans_details_secure_core_servers = NSLocalizedString("New_Plans Secure Core servers", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details Secure Core servers")
    
    /// Plan details tor over VPN
    public lazy var _new_plans_details_tor_over_vpn = NSLocalizedString("New_Plans TOR over VPN", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details TOR over VPN")

    /// Plan details P2P
    public lazy var _new_plans_details_p2p = NSLocalizedString("New_Plans P2P/BitTorrent", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details P2P/BitTorrent")

    /// Get plan button
    public lazy var _new_plans_get_plan_button = NSLocalizedString("New_Plans Get %@", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Get plan button")
    
    /// Get free plan button
    public lazy var _new_plans_get_free_plan_button = NSLocalizedString("New_Plans Get Proton for free", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Get free plan button")
    
    /// Get free plan button
    public lazy var _new_plans_extend_subscription_button = NSLocalizedString("New_Plans Extend subscription", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Extend subscription button")

    /// Plan details used storage space
    public lazy var _new_plans_details_used_storage_space = NSLocalizedString("New_Plans %@ of %@", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details used storage space")

    /// Plan connection error title
    public lazy var _new_plans_connection_error_title = NSLocalizedString("New_Plans Connection issues", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan connection error title")
    
    /// Plan connection error description
    public lazy var _new_plans_connection_error_description = NSLocalizedString("New_Plans Check your internet connection", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan connection error description")
    
    /// Plan details VPN no logs policy
    public lazy var _new_plans_details_no_logs_policy = NSLocalizedString("New_Plans Strict no-logs policy", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan details no logs policy")

    /// Plan details VPN no logs policy
    public lazy var _new_plans_plan_successfully_upgraded = NSLocalizedString("New_Plans Plan successfully upgraded", tableName: "Localizable_V5", bundle: Common_V5.bundle, comment: "New_Plans Plan successfully upgraded banner message")
}
