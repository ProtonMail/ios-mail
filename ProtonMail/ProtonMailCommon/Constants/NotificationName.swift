//
//  NotificationDefined.swift
//  ProtonMail - Created on 8/11/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        return .init(rawValue: "UserDataServiceDidSignInNotification")
    }
}
