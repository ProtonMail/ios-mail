//
//  Settings+Defined.swift
//  ProtonMail - Created on 6/5/17.
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

//settings language item  ***!!! this need match with LanguageManager.h
extension ELanguage {
    
    public var nativeDescription : String {
        get {
            switch(self) {
            case .english:
                return "English"
            case .german:
                return "Deutsch"
            case .french:
                return "Français"
            case .russian:
                return "Русский"
            case .spanish:
                return "Español"
            case .turkish:
                return "Türkçe"
            case .polish:
                return "Polski"
            case .ukrainian:
                return "Українська"
            case .dutch:
                return "Dutch"
            case .italian:
                return "Italiano"
            case .portugueseBrazil:
                return "Português do Brasil"
            case .chineseSimplified:
                return "简体中文"
            case .chineseTraditional:
                return "繁體中文"
            case .catalan:
                return "Català"
            case .danish:
                return "Dansk"
            case  .czech:
                return "Čeština"
            case .portuguese:
                return "Português"
            case .romanian:
                return "Română"
            case .croatian:
                return "Hrvatski"
            case .hungarian:
                return "Magyar"
            case .icelandic:
                return "íslenska"
            case .kabyle:
                return "Taqbaylit"
            case .swedish:
                return "Svenska"
            case .japanese:
                return "日本語"
            case .indonesian:
                return "bahasa Indonesia"
            case .count:
                return ""
            @unknown default:
                return ""
            }
        }
    }
    
    public var localeString : String {
        get {
            switch(self) {
            case .english:
                return "en_US"
            case .german:
                return "de_DE"
            case .french:
                return "fr_FR"
            case .russian:
                return "ru_RU"
            case .spanish:
                return "es_ES"
            case .turkish:
                return "tr_TR"
            case .polish:
                return "pl_PL"
            case .ukrainian:
                return "uk_UA"
            case .dutch:
                return "nl_NL"
            case .italian:
                return "it_IT"
            case .portugueseBrazil:
                return "pt_BR"
            case .chineseSimplified:
                return "zh_CN"
            case .chineseTraditional:
                return "zh_TW"
            case .catalan:
                return "ca_ES"
            case .danish:
                return "da_DK"
            case .czech:
                return "cs_CZ"
            case .portuguese:
                return "pt_PT"
            case .romanian:
                return "ro_RO"
            case .croatian:
                return "hr-HR"
            case .hungarian:
                return "hu_HU"
            case .icelandic:
                return "is-rIS"
            case .kabyle:
                return "kab-DZ"
            case .swedish:
                return "sv_SE"
            case .japanese:
                return "ja_JP"
            case .indonesian:
                return "in_ID"
            case .count:
                return "en_US"
            @unknown default:
                return "en_US"
            }
        }
    }
    
    //This code needs to match the project language folder
    public var code : String {
        get {
            switch(self) {
            case .english:
                return "en"
            case .german:
                return "de"
            case .french:
                return "fr"
            case .russian:
                return "ru"
            case .spanish:
                 return "es"
            case .turkish:
                return "tr"
            case .polish:
                return "pl"
            case .ukrainian:
                return "uk"
            case .dutch:
                return "nl"
            case .italian:
                return "it"
            case .portugueseBrazil:
                return "pt-BR"
            case .chineseSimplified:
                return "zh-Hans"
            case .chineseTraditional:
                return "zh-Hant"
            case .catalan:
                return "ca"
            case .danish:
                return "da"
            case .czech:
                return "cs"
            case .portuguese:
                return "pt"
            case .romanian:
                return "ro"
            case .croatian:
                return "hr"
            case .hungarian:
                return "hu"
            case .icelandic:
                return "is"
            case .kabyle:
                return "kab"
            case .swedish:
                return "sv"
            case .japanese:
                return "ja"
            case .indonesian:
                return "id"
            case .count:
                return "en"
            @unknown default:
                return "en"
            }
        }
    }

//    static public func allItemsCode() -> [String] {
//        return [ELanguage.english.code,
//                ELanguage.german.code,
//                ELanguage.french.code,
//                ELanguage.russian.code,
//                ELanguage.spanish.code,
//                ELanguage.turkish.code,
//                ELanguage.polish.code,
//                ELanguage.ukrainian.code,
//                ELanguage.dutch.code,
//                ELanguage.italian.code,
//                ELanguage.portugueseBrazil.code,
//                ELanguage.chineseSimplified.code,
//                ELanguage.chineseTraditional.code,
//                ELanguage.catalan.code,
//                ELanguage.danish.code,
//                ELanguage.czech.code,
//                ELanguage.portuguese.code,
//                ELanguage.romanian.code
//        ]
//    }
    static public func allItems() -> [ELanguage] {
        return [
            .catalan,
            .croatian,
            .czech,
            .chineseSimplified,
            .chineseTraditional,
            .danish,
            .dutch,
            .english,
            .french,
            .german,
            .hungarian,
            .icelandic,
            .indonesian,
            .italian,
            .japanese,
            .kabyle,
            .polish,
            .portuguese,
            .portugueseBrazil,
            .romanian,
            .russian,
            .spanish,
            .swedish,
            .turkish,
            .ukrainian,
        ]
    }
}

public enum SDebugItem: Int, CustomStringConvertible {
    case queue = 0
    case errorLogs = 1
    public var description : String {
        switch(self){
        case .queue:
            return LocalString._message_queue
        case .errorLogs:
            return LocalString._error_logs
        }
    }
}

public enum SGItems: Int, CustomStringConvertible {
    case notifyEmail = 0
    //        case DisplayName = 1
    //        case Signature = 2
    case loginPWD = 3
    case mbp = 4
    case cleanCache = 5
    case autoLoadImage = 9
    case singlePWD = 10
    case notificationsSnooze = 11
    case linkOpeningMode = 12
    case metadataStripping = 13
    case browser
    
    public var description : String {
        switch(self){
        case .notifyEmail:
            return LocalString._settings_notification_email
        case .loginPWD:
            return LocalString._login_password
        case .mbp:
            return LocalString._mailbox_password
        case .singlePWD:
            return LocalString._single_password
        case .cleanCache:
            return LocalString._clear_local_message_cache
        case .autoLoadImage:
            return LocalString._auto_show_images
        case .notificationsSnooze:
            return LocalString._snooze_notifications
        case .linkOpeningMode:
            return LocalString._request_link_confirmation
        case .metadataStripping:
            return LocalString._strip_metadata
        case .browser:
            return LocalString._default_browser
        }
    }
}

public enum SSwipeActionItems: Int, CustomStringConvertible {
    case left = 0
    case right = 1
    
    public var description : String {
        switch(self){
        case .left:
            return LocalString._swipe_left_to_right
        case .right:
            return LocalString._swipe_right_to_left
        }
    }
    
    public var actionDescription : String {
        switch(self){
        case .left:
            return LocalString._change_left_swipe_action
        case .right:
            return LocalString._change_right_swipe_action
        }
    }
}

public enum SProtectionItems : Int, CustomStringConvertible {
    case touchID = 0
    case pinCode = 1
    case updatePin = 2
    case autoLogout = 3
    case enterTime = 4
    case faceID = 5
    
    public var description : String {
        switch(self){
        case .touchID:
            return LocalString._enable_touchid
        case .pinCode:
            return LocalString._enable_pin_protection
        case .updatePin:
            return LocalString._change_pin
        case .autoLogout:
            return LocalString._protection_entire_app
        case .enterTime:
            return LocalString._settings_auto_lock_time
        case .faceID:
            return LocalString._enable_faceid
        }
    }
}

public enum SAddressItems: Int, CustomStringConvertible {
    case addresses = 0
    case displayName = 1
    case signature = 2
    case defaultMobilSign = 3
    
    public var description : String {
        switch(self){
        case .addresses:
            return ""
        case .displayName:
            return LocalString._settings_display_name_title
        case .signature:
            return LocalString._settings_signature_title
        case .defaultMobilSign:
            return LocalString._settings_mobile_signature_title
        }
    }
}

public enum SLabelsItems: Int, CustomStringConvertible {
    case labelFolderManager = 0
    public var description : String {
        switch(self){
        case .labelFolderManager:
            return LocalString._labels_manage_title
        }
    }
}


public enum SNetworkItems: Int, CustomStringConvertible {
    case doh = 0
    case clear = 1
    public var description : String {
        switch(self){
        case .doh:
            return "DNS over Https"
        case .clear:
            return "Reset DNS Cache"
        }
    }
}


public enum SettingSections: Int, CustomStringConvertible {
    case debug = 0
    case general = 1
    case multiDomain = 2
    case storage = 3
    case version = 4
    case swipeAction = 5
    case protection = 6
    case language = 7
    case labels = 8
    case network = 9
    
    public var description : String {
        switch(self){
        case .debug:
            return LocalString._debug
        case .general:
            return LocalString._general_settings
        case .multiDomain:
            return LocalString._multiple_addresses
        case .storage:
            return LocalString._storage
        case .version:
            return ""
        case .swipeAction:
            return LocalString._message_swipe_actions
        case .protection:
            return LocalString._protection
        case .language:
            return LocalString._language
        case .labels:
            return LocalString._labels_folders
        case .network:
            return LocalString._networking
        }
    }
}

