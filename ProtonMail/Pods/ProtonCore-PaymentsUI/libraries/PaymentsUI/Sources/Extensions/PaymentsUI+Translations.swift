//
//  PaymentsUI+Bundle.swift
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

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum PUITranslations: TranslationsExposing {
    
    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-PaymentsUI", ofType: "bundle")!)!
        #endif
    }
    
    public static var prefixForMissingValue: String = ""
    
    case _core_ok_button
    case _core_cancel_button
    case _payments_warning
    case select_plan_title
    case current_plan_title
    case subscription_title
    case upgrade_plan_title
    case plan_footer_desc
    case plan_footer_desc_purchased
    case plan_details_renew_auto_expired
    case plan_details_renew_expired
    case plan_details_plan_details_unavailable_contact_administrator
    case plan_details_storage
    case plan_details_storage_per_user
    case plan_details_price_time_period_no_unit
    case plan_details_custom_email
    case plan_details_priority_support
    case plan_details_adblocker
    case plan_details_streaming_service
    case plan_details_high_speed
    case plan_details_highest_speed
    case plan_details_multi_user_support
    case plan_details_free_price
    case plan_details_free_description
    case plan_details_plus_description
    case plan_limited_time_offer
    case plan_unfinished_error_title
    case plan_unfinished_error_desc
    case plan_unfinished_error_retry_button
    case plan_unfinished_desc
    case iap_in_progress_banner
    case plan_details_n_users
    case plan_details_n_addresses
    case plan_details_n_addresses_per_user
    case plan_details_n_calendars
    case plan_details_n_folders
    case plan_details_countries
    case plan_details_n_connections
    case plan_details_n_vpn_connections
    case plan_details_n_high_speed_connections
    case plan_details_n_custom_domains
    case plan_cycle_one_month
    case plan_cycle_one_year
    case plan_cycle_two_years
    case plan_cycle_x_months
    case _details_n_custom_email_domains
    case _details_n_folders_labels
    case _details_n_calendars
    case _details_vpn_on_n_devices
    case _details_vpn_servers
    case _details_vpn_free_servers
    case _details_vpn_free_speed_n_connections
    case _details_n_of_m_users
    case _details_n_of_m_addresses
    case _details_n_of_m_calendars
    case _details_n_addresses_per_user
    case _details_n_calendars_per_user
    case _details_n_connections_per_user
    case _plan_details_n_vaults
    case _select_plan_description
    case _plan_details_free_description
    case _plan_details_plus_description
    case _plan_details_vpn_plus_description
    case _new_plan_details_drive_plus_description
    case _plan_details_bundle_description
    case _plan_footer_desc
    case _details_unlimited_folders_labels_filters
    case _details_up_to_storage
    case _details_vpn_on_single_device
    case _details_highest_VPN_speed
    case _detailsblocker
    case _details_access_streaming_services
    case _details_secure_core_servers
    case _details_tor_over_vpn
    case _details_p2p
    case _get_plan_button
    case _get_free_plan_button
    case _extend_subscription_button
    case _details_used_storage_space
    case _connection_error_title
    case _connection_error_description
    case _details_no_logs_policy
    case _plan_successfully_upgraded
    case _plan_details_2fa_authenticator
    case _plan_details_priority_support
    case _plan_details_devices_unlimited
    case _plan_details_email_aliases_number
    case _plan_details_email_aliases_unlimited
    case _plan_details_logins_and_notes_unlimited
    case _plan_details_forwarding_mailboxes
    case _plan_details_custom_fields
    case _plan_pass_description
    
    public var l10n: String {
        switch self {
        case ._core_ok_button:
            return localized(key: "OK", comment: "OK button")
        case ._core_cancel_button:
            return localized(key: "Cancel", comment: "Cancel button")
        case ._payments_warning:
            return localized(key: "Warning", comment: "Title")
        case .select_plan_title:
            return localized(key: "Select a plan", comment: "Plan selection title")
        case .current_plan_title:
            return localized(key: "Current plan", comment: "Plan selection title")
        case .subscription_title:
            return localized(key: "Subscription", comment: "Subscription title")
        case .upgrade_plan_title:
            return localized(key: "Upgrade your plan", comment: "Plan selection title")
        case .plan_footer_desc:
            return localized(key: "Only annual subscriptions without auto-renewal are available inside the mobile app.", comment: "Plan footer description")
        case .plan_footer_desc_purchased:
            return localized(key: "You cannot manage subscriptions inside the mobile application.", comment: "Plan footer purchased description")
        case .plan_details_renew_auto_expired:
            return localized(key: "Your plan will automatically renew on %@", comment: "Plan details renew automatically expired")
        case .plan_details_renew_expired:
            return localized(key: "Current plan will expire on %@", comment: "Plan details renew expired")
        case .plan_details_plan_details_unavailable_contact_administrator:
            return localized(key: "Contact an administrator to make changes to your Proton subscription.", comment: "Plan details unavailable contact administrator")
        case .plan_details_storage:
            return localized(key: "%@ storage", comment: "Plan details storage")
        case .plan_details_storage_per_user:
            return localized(key: "%@ storage / user", comment: "Plan details storage per user")
        case .plan_details_price_time_period_no_unit:
            return localized(key: "for %@", comment: "Plan details price time period without unit — we delegate the units formatting to the operating system. Example: for 1 year 3 months")
        case .plan_details_custom_email:
            return localized(key: "Custom email addresses", comment: "Plan details custom email addresses")
        case .plan_details_priority_support:
            return localized(key: "Priority customer support", comment: "Plan details priority customer support")
        case .plan_details_adblocker:
            return localized(key: "Adblocker (NetShield)", comment: "Plan details adblocker")
        case .plan_details_streaming_service:
            return localized(key: "Streaming service support", comment: "Plan details streaming service support")
        case .plan_details_high_speed:
            return localized(key: "High speed", comment: "Plan details high speed message")
        case .plan_details_highest_speed:
            return localized(key: "Highest speed", comment: "Plan details highest speed message")
        case .plan_details_multi_user_support:
            return localized(key: "Multi-user support", comment: "Plan details multi-user support message")
        case .plan_details_free_price:
            return localized(key: "Free", comment: "Plan price when it's free")
        case .plan_details_free_description:
            return localized(key: "The basic for private and secure communications.", comment: "Plan details free description")
        case .plan_details_plus_description:
            return localized(key: "Full-featured mailbox with advanced protection.", comment: "Plan details plus description")
        case .plan_limited_time_offer:
            return localized(key: "Limited time offer", comment: "Badge under plan name indicating a limited time offer (promo price)")
        case .plan_unfinished_error_title:
            return localized(key: "Complete payment?", comment: "Unfinished operation error dialog title")
        case .plan_unfinished_error_desc:
            return localized(key: "A purchase for a Proton Bundle plan has already been initiated. Press continue to complete the payment processing and create your account", comment: "Unfinished operation error dialog description")
        case .plan_unfinished_error_retry_button:
            return localized(key: "Complete payment", comment: "Unfinished operation error dialog retry button")
        case .plan_unfinished_desc:
            return localized(key: "The account setup process could not be finalized due to an unexpected error.\nPlease try again.", comment: "Unfinished operation dialog description")
        case .iap_in_progress_banner:
            return localized(key: "The IAP purchase process has started. Please follow Apple's instructions to either complete or cancel the purchase.", comment: "IAP in progress banner message")
        case .plan_details_n_users:
            return localized(key: "%d users", comment: "Plan details n users")
        case .plan_details_n_addresses:
            return localized(key: "%d email addresses", comment: "Plan details n addresses")
        case .plan_details_n_addresses_per_user:
            return localized(key: "%d email addresses / user", comment: "Plan details n address per user")
        case .plan_details_n_calendars:
            return localized(key: "%d calendars", comment: "Plan details n calendar")
        case .plan_details_n_folders:
            return localized(key: "%d folders / labels", comment: "Plan details n folders / labels")
        case .plan_details_countries:
            return localized(key: "%d countries", comment: "Plan details n countries")
        case .plan_details_n_connections:
            return localized(key: "%d connections", comment: "Plan details n connections")
        case .plan_details_n_vpn_connections:
            return localized(key: "%d VPN connections", comment: "Plan details n VPN connections")
        case .plan_details_n_high_speed_connections:
            return localized(key: "%d high-speed VPN connections", comment: "Plan details n high-speed connections")
        case .plan_details_n_custom_domains:
            return localized(key: "%d custom domains", comment: "Plan details n custom domains")
        case .plan_cycle_one_month:
            return localized(key: "Pay monthly", comment: "Selecting a one month recurring payment cycle")
        case .plan_cycle_one_year:
            return localized(key: "Pay annually", comment: "Selecting a one year recurring payment cycle")
        case .plan_cycle_two_years:
            return localized(key: "Pay every two years", comment: "Selecting a two years recurring payment cycle")
        case .plan_cycle_x_months:
            return localized(key: "Pay for %d months", comment: "Selecting a X months recurring payment cycle")
        case ._details_n_custom_email_domains:
            return localized(key: "Support for %d custom email domains", comment: "details n custom email domains")
        case ._details_n_folders_labels:
            return localized(key: "%d folders and labels", comment: "Plan details n folders and labels")
        case ._details_n_calendars:
            return localized(key: "%d calendars", comment: "Plan details n calendars")
        case ._details_vpn_on_n_devices:
            return localized(key: "High-speed VPN on %d devices", comment: "Plan details VPN on n devices")
        case ._details_vpn_servers:
            return localized(key: "%d+ servers in %d countries", comment: "Plan details n servers in m countries")
        case ._details_vpn_free_servers:
            return localized(key: "%d servers in %d countries (US, NL, JP)", comment: "Plan details free n servers in m countries")
        case ._details_vpn_free_speed_n_connections:
            return localized(key: "Medium VPN speed %d VPN connections", comment: "Plan details free speed n VPN connections")
        case ._details_n_of_m_users:
            return localized(key: "%d of %d users", comment: "Plan details n of m users")
        case ._details_n_of_m_addresses:
            return localized(key: "%d of %d email addresses", comment: "Plan details n addresses")
        case ._details_n_of_m_calendars:
            return localized(key: "%d of %d calendars", comment: "Plan details n of m calendars")
        case ._details_n_addresses_per_user:
            return localized(key: "%d addresses per user", comment: "Plan details n addresses per user")
        case ._details_n_calendars_per_user:
            return localized(key: "%d calendars per user", comment: "Plan details n calendars per user")
        case ._details_n_connections_per_user:
            return localized(key: "%d VPN connections per user", comment: "Plan details n connections per user")
        case ._plan_details_n_vaults:
            return localized(key: "%d vaults", comment: "Plan details n vaults")
        case ._select_plan_description:
            return localized(key: "One plan for all Proton services", comment: "Plan selection title")
        case ._plan_details_free_description:
            return localized(key: "The no-cost starter account designed to empower everyone with privacy by default.", comment: "Plan details free description")
        case ._plan_details_plus_description:
            return localized(key: "The privacy-first email and calendar solution for your everyday communication needs.", comment: "Plan details plus description")
        case ._plan_details_vpn_plus_description:
            return localized(key: "Your privacy and security are our priority.", comment: "Plan details vpn plus description")
        case ._new_plan_details_drive_plus_description:
            return localized(key: "The storage-focused plan with 200 GB of cloud storage to keep your files private.", comment: "Plan details drive plus description")
        case ._plan_details_bundle_description:
            return localized(key: "The ultimate privacy pack with access to all premium Proton services.", comment: "Plan details bundle description")
        case ._plan_footer_desc:
            return localized(key: "Only non-renewing annual subscriptions are available via this app", comment: "Plan footer description")
        case ._details_unlimited_folders_labels_filters:
            return localized(key: "Unlimited folders, labels, and filters", comment: "Plan details unlimited folders, labels, filters")
        case ._details_up_to_storage:
            return localized(key: "Up to %@ storage", comment: "Plan details up to storage")
        case ._details_vpn_on_single_device:
            return localized(key: "Free VPN on a single device", comment: "Plan details VPN on a single device")
        case ._details_highest_VPN_speed:
            return localized(key: "Highest VPN speed", comment: "Plan details Highest VPN speed")
        case ._detailsblocker:
            return localized(key: "Built-in ad-blocker (NetShield)", comment: "Plan details ad-blocker")
        case ._details_access_streaming_services:
            return localized(key: "Access to streaming services globally", comment: "Plan details Access to streaming services globally")
        case ._details_secure_core_servers:
            return localized(key: "Secure Core servers", comment: "Plan details Secure Core servers")
        case ._details_tor_over_vpn:
            return localized(key: "TOR over VPN", comment: "Plan details TOR over VPN")
        case ._details_p2p:
            return localized(key: "P2P/BitTorrent", comment: "Plan details P2P/BitTorrent")
        case ._get_plan_button:
            return localized(key: "Get %@", comment: "Get plan button")
        case ._get_free_plan_button:
            return localized(key: "Get Proton for free", comment: "Get free plan button")
        case ._extend_subscription_button:
            return localized(key: "Extend subscription", comment: "Extend subscription button")
        case ._details_used_storage_space:
            return localized(key: "%@ of %@", comment: "Plan details used storage space")
        case ._connection_error_title:
            return localized(key: "Connection issues", comment: "Plan connection error title")
        case ._connection_error_description:
            return localized(key: "Check your internet connection", comment: "Plan connection error description")
        case ._details_no_logs_policy:
            return localized(key: "Strict no-logs policy", comment: "Plan details no logs policy")
        case ._plan_successfully_upgraded:
            return localized(key: "Plan successfully upgraded", comment: "Plan successfully upgraded banner message")
        case ._plan_details_2fa_authenticator:
            return localized(key: "Integrated 2FA authenticator", comment: "Plan details `Integrated 2FA authenticator` message")
        case ._plan_details_priority_support:
            return localized(key: "Priority support", comment: "Plan details `Priority support` message")
        case ._plan_details_devices_unlimited:
            return localized(key: "Unlimited devices", comment: "Plan details `Unlimited devices` message")
        case ._plan_details_email_aliases_number:
            return localized(key: "%@ email aliases", comment: "Plan details number of email aliases message")
        case ._plan_details_email_aliases_unlimited:
            return localized(key: "Unlimited email aliases", comment: "Plan details `Unlimited email aliases` message")
        case ._plan_details_logins_and_notes_unlimited:
            return localized(key: "Unlimited logins and notes", comment: "Plan details `Unlimited logins and notes` message")
        case ._plan_details_forwarding_mailboxes:
            return localized(key: "Up to %@ forwarding mailboxes", comment: "Plan details `Up to %@ forwarding mailboxes` message")
        case ._plan_details_custom_fields:
            return localized(key: "Custom fields", comment: "Plan details `Custom fields` message")
        case ._plan_pass_description:
            return localized(key: "For next-level password management and identity protection.", comment: "Description of the Pass plan")
        }
    }
}
