//
//  OnboardingObject.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/24/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


public enum Onboarding: Int, Printable {
    case welcome = 0
    case swipe = 1
    case label = 2
    case encryption = 3
    case expire = 4
    case help = 5
    
    public var image : String {
        get {
            switch(self) {
            case welcome:
                return "onboarding_welcome"
            case swipe:
                return "onboarding_swipe"
            case label:
                return "onboarding_labels"
            case encryption:
                return "onboarding_encryption"
            case expire:
                return "onboarding_expire"
            case help:
                return "onboarding_help"
            }
        }
    }
    
    public var description : String {
        get {
            switch(self) {
            case welcome:
                return NSLocalizedString("Your new encrypted email account has been set up and is ready to send and recieve encrypted messages.")
            case swipe:
                return NSLocalizedString("You can customize swipe gestures in the ProtonMail App Settings.")
            case label:
                return NSLocalizedString("Create and add Labels to organize your inbox. Press and hold down on a message for all options.")
            case encryption:
                return NSLocalizedString("Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail.")
            case expire:
                return NSLocalizedString("Messages you send can be set to auto delete after a certain time period.")
            case help:
                return NSLocalizedString("You can get help and support at protonmail.com/support. Bugs can also be reported with the app.")
            }
        }
    }
    
    public var title : String {
        get {
            switch(self) {
            case welcome:
                return NSLocalizedString("Welcome to ProtonMail!")
            case swipe:
                return NSLocalizedString("Quick swipe actions")
            case label:
                return NSLocalizedString("Label Management")
            case encryption:
                return NSLocalizedString("End-to-End Encryption")
            case expire:
                return NSLocalizedString("Expiring Messages")
            case help:
                return NSLocalizedString("Help & Support")
            }
        }
    }
    
}