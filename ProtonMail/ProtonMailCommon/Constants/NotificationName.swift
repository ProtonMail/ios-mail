//
//  NotificationDefined.swift
//  ProtonMail - Created on 8/11/15.
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
    
    /// when received a custom url schema. ex. verify code
    static var customUrlSchema: Notification.Name {
        return .init(rawValue: "Application.CustomUrlSchema")
    }
    
    /// notify did signout
    static var didSignOut: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignOutNotification")
    }
    
    /// notify did signin
    static var didSignIn: Notification.Name {
        return .init(rawValue: "UserDataServiceDidSignInNotification")
    }
    
    /// notify did unlock
    static var didUnlock: Notification.Name {
        return .init(rawValue: "UserDataServiceDidUnlockNotification")
    }
    
    static var didObtainMailboxPassword: Notification.Name {
        return .init(rawValue: "UserDataServiceDidObtainMailboxPasswordNotification")
    }
    
    /// notify token revoke
    static var didRevoke: Notification.Name {
        return .init("ApiTokenRevoked")
    }
    
    ///notify when primary account is revoked
    static var didPrimaryAccountLogout: Notification.Name {
        return .init("didPrimaryAccountLogout")
    }
}
