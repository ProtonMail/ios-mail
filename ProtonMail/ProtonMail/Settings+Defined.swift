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
                return NSLocalizedString("English", comment: "Action")
            case .german:
                return NSLocalizedString("German", comment: "Action")
            case .french:
                return NSLocalizedString("French", comment: "Action")
            case .russian:
                return NSLocalizedString("Russian", comment: "Action")
            case .spanish:
                return NSLocalizedString("Spanish", comment: "Action")
            case .turkish:
                return NSLocalizedString("Turkish", comment: "Action")
            case .polish:
                return NSLocalizedString("Polish", comment: "Action")
            case .ukrainian:
                return NSLocalizedString("Ukrainian", comment: "Action")
            case .dutch:
                return NSLocalizedString("Dutch", comment: "Action")
            case .italian:
                return NSLocalizedString("Italian", comment: "Action")
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
            case .count:
                return "en_US"
            }
        }
    }
    
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
                .italian
        ]
    }
}

public enum SDebugItem: Int, CustomStringConvertible {
    case queue = 0
    case errorLogs = 1
    public var description : String {
        switch(self){
        case .queue:
            return NSLocalizedString("Message Queue", comment: "settings debug section title")
        case .errorLogs:
            return NSLocalizedString("Error Logs", comment: "settings debug section title")
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
    
    public var description : String {
        switch(self){
        case .notifyEmail:
            return NSLocalizedString("Notification Email", comment: "settings general section title")
        case .loginPWD:
            return NSLocalizedString("Login Password", comment: "settings general section title")
        case .mbp:
            return NSLocalizedString("Mailbox Password", comment: "settings general section title")
        case .singlePWD:
            return NSLocalizedString("Single Password", comment: "settings general section title")
        case .cleanCache:
            return NSLocalizedString("Clear Local Message Cache", comment: "settings general section title")
        case .autoLoadImage:
            return NSLocalizedString("Auto Show Images", comment: "settings general section title")
        }
    }
}

public enum SSwipeActionItems: Int, CustomStringConvertible {
    case left = 0
    case right = 1
    
    public var description : String {
        switch(self){
        case .left:
            return NSLocalizedString("Swipe Left to Right", comment: "settings swipe actions section title")
        case .right:
            return NSLocalizedString("Swipe Right to Left", comment: "settings swipe actions section title")
        }
    }
    
    public var actionDescription : String {
        switch(self){
        case .left:
            return NSLocalizedString("Change left swipe action", comment: "settings swipe actions section action description")
        case .right:
            return NSLocalizedString("Change right swipe action", comment: "settings swipe actions section action description")
        }
    }
}

public enum SProtectionItems : Int, CustomStringConvertible {
    case touchID = 0
    case pinCode = 1
    case updatePin = 2
    case autoLogout = 3
    case enterTime = 4
    
    public var description : String {
        switch(self){
        case .touchID:
            return NSLocalizedString("Enable TouchID", comment: "settings protection section title")
        case .pinCode:
            return NSLocalizedString("Enable Pin Protection", comment: "settings protection section title")
        case .updatePin:
            return NSLocalizedString("Change Pin", comment: "settings protection section title")
        case .autoLogout:
            return NSLocalizedString("Protection Entire App", comment: "settings protection section title")
        case .enterTime:
            return NSLocalizedString("Auto Lock Time", comment: "settings protection section title")
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
            return NSLocalizedString("", comment: "")
        case .displayName:
            return NSLocalizedString("Display Name", comment: "Title")
        case .signature:
            return NSLocalizedString("Signature", comment: "Title")
        case .defaultMobilSign:
            return NSLocalizedString("Mobile Signature", comment: "Title")
        }
    }
}

public enum SLabelsItems: Int, CustomStringConvertible {
    case labelFolderManager = 0
    public var description : String {
        switch(self){
        case .labelFolderManager:
            return NSLocalizedString("Manage Labels/Folders", comment: "Title")
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
    
    public var description : String {
        switch(self){
        case .debug:
            return NSLocalizedString("Debug", comment: "Title")
        case .general:
            return NSLocalizedString("General Settings", comment: "Title")
        case .multiDomain:
            return NSLocalizedString("Multiple Addresses", comment: "Title")
        case .storage:
            return NSLocalizedString("Storage", comment: "Title")
        case .version:
            return NSLocalizedString("", comment: "")
        case .swipeAction:
            return NSLocalizedString("Message Swipe Actions", comment: "Title")
        case .protection:
            return NSLocalizedString("Protection", comment: "Title")
        case .language:
            return NSLocalizedString("Language", comment: "Title")
        case .labels:
            return NSLocalizedString("Labels/Folders", comment: "Title")
        }
    }
}

