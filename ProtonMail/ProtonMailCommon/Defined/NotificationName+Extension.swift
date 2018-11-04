//
//  NotificationDefined.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/11/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension Notification.Name {
    
    /// notify menu controller to switch views
    static var switchView: Notification.Name {
        return .init(rawValue: "MenuController.SwitchView")
    }
    
    /// notify when status bar is clicked
    static var touchStatusBar: Notification.Name {
        return .init(rawValue: "Application.TouchStatusBar")
    }
    
    /// notify user the app need to be upgraded
    static var forceUpgrade: Notification.Name {
        return .init(rawValue: "Application.ForceUpgrade")
    }
    
    static var didSignOut: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignOutNotification")
    }
    
    static var didUnlock: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignInNotification")
    }
}


struct NotificationDefined {
    
    static let CustomizeURLSchema = "customize_url_schema"
    
    //static public let languageWillChange = "PM_LANGUAGE_WILL_CHANGE"
    static public let languageDidChange = "PM_LANGUAGE_DID_CHANGE"
    
}
