//
//  Onboarding.swift
//  ProtonMail - Created on 2/24/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


public enum Onboarding: Int, CustomStringConvertible {
    case welcome = 0
    case swipe = 1
    case label = 2
    case encryption = 3
    case expire = 4
    case help = 5
    case upgrade = 6
    
    public var image : String {
        get {
            switch(self) {
            case .welcome:
                return "onboarding_welcome"
            case .swipe:
                return "onboarding_swipe"
            case .label:
                return "onboarding_labels"
            case .encryption:
                return "onboarding_encryption"
            case .expire:
                return "onboarding_expire"
            case .help:
                return "onboarding_help"
            case .upgrade:
                return "onboarding_upgrade"
            }
        }
    }
    
    public var description : String {
        get {
            switch(self) {
            case .welcome:
                return LocalString._your_new_account_is_ready_to_send_and_receive_encrypted_messages
            case .swipe:
                return LocalString._you_can_customize_swipe_in_app_settings
            case .label:
                return LocalString._create_and_add_labels_to_organize_inbox_and_hold_down_on_a_message_for_all_options
            case .encryption:
                return LocalString._your_inbox_is_now_protected_with_e2e_you_can_also_do_eo
            case .expire:
                return LocalString._messages_you_send_can_be_set_to_auto_delete_after_a_certain_time_period
            case .help:
                return LocalString._you_can_get_help_and_support_at_protonmail_support_and_bugs
            case .upgrade:
                return LocalString._protonmail_doesnt_sell_ads_or_abuse_your_privacy
            }
        }
    }
    
    public var title : String {
        get {
            switch(self) {
            case .welcome:
                return LocalString._welcome_to_protonmail
            case .swipe:
                return LocalString._quick_swipe_actions
            case .label:
                return LocalString._label_management
            case .encryption:
                return LocalString._end_to_end_encryption
            case .expire:
                return LocalString._expiring_messages
            case .help:
                return LocalString._help_and_support
            case .upgrade:
                return LocalString._support_protonmail
            }
        }
    }
    
}
