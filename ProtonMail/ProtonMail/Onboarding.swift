//
//  OnboardingObject.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/24/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

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
                return NSLocalizedString("Your new encrypted email account has been set up and is ready to send and receive encrypted messages.", comment: "Description")
            case .swipe:
                return NSLocalizedString("You can customize swipe gestures in the ProtonMail App Settings.", comment: "Description")
            case .label:
                return NSLocalizedString("Create and add Labels to organize your inbox. Press and hold down on a message for all options.", comment: "Description")
            case .encryption:
                return NSLocalizedString("Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail.", comment: "Description")
            case .expire:
                return NSLocalizedString("Messages you send can be set to auto delete after a certain time period.", comment: "Description")
            case .help:
                return NSLocalizedString("You can get help and support at protonmail.com/support. Bugs can also be reported with the app.", comment: "Description")
            case .upgrade:
                return NSLocalizedString("ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail.", comment: "Description")
            }
        }
    }
    
    public var title : String {
        get {
            switch(self) {
            case .welcome:
                return NSLocalizedString("Welcome to ProtonMail!", comment: "Title")
            case .swipe:
                return NSLocalizedString("Quick swipe actions", comment: "Title")
            case .label:
                return NSLocalizedString("Label Management", comment: "Title")
            case .encryption:
                return NSLocalizedString("End-to-End Encryption", comment: "Title")
            case .expire:
                return NSLocalizedString("Expiring Messages", comment: "Title")
            case .help:
                return NSLocalizedString("Help & Support", comment: "Title")
            case .upgrade:
                return NSLocalizedString("Support ProtonMail", comment: "Title")
            }
        }
    }
    
}
