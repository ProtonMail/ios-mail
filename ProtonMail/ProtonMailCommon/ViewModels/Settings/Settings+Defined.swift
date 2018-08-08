//
//  Settings+Defined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

//settings language item  ***!!! this need match with LanguageManager.h

extension ELanguage {
    
    public var description : String {
        get {
            switch(self) {
            case .english:
                return LocalString._english
            case .german:
                return LocalString._german
            case .french:
                return LocalString._french
            case .russian:
                return LocalString._russian
            case .spanish:
                return LocalString._spanish
            case .turkish:
                return LocalString._turkish
            case .polish:
                return LocalString._polish
            case .ukrainian:
                return LocalString._ukrainian
            case .dutch:
                return LocalString._dutch
            case .italian:
                return LocalString._italian
            case .portugueseBrazil:
                return LocalString._portuguese_brazil
            case .count:
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
            case .count:
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
            case .count:
                return "en"
            }
        }
    }

    static public func allItemsCode() -> [String] {
        return [ELanguage.english.code,
                ELanguage.german.code,
                ELanguage.french.code,
                ELanguage.russian.code,
                ELanguage.spanish.code,
                ELanguage.turkish.code,
                ELanguage.polish.code,
                ELanguage.ukrainian.code,
                ELanguage.dutch.code,
                ELanguage.italian.code,
                ELanguage.portugueseBrazil.code
        ]
    }
    static public func allItems() -> [ELanguage] {
        return [.english,
                .german,
                .french,
                .russian,
                .spanish,
                .turkish,
                .polish,
                .ukrainian,
                .dutch,
                .italian,
                .portugueseBrazil
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
    case servicePlan = 9
    
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
        case .servicePlan:
            return "SERVICE PLAN" //FIX ME
        }
    }
}

