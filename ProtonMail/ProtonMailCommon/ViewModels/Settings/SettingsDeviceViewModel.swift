//
//  SettingsViewModel.swift
//  ProtonMail - Created on 12/12/18.
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

public enum SettingDeviceSection : Int, CustomStringConvertible {
    case account = 0
    case app = 1
    case info = 2
    case network = 3
    
    public var description : String {
        switch(self){
        case .account:
            return LocalString._account_settings
        case .app:
            return LocalString._app_settings
        case .info:
            return LocalString._app_information
        case .network:
            return LocalString._networking
        }
    }
}

public enum DeviceSectionItem : Int, CustomStringConvertible {
    case autolock = 0
    case language = 1
    case combinContacts = 2
    case cleanCache = 3
    case push = 4
    case browser = 5
    
    public var description : String {
        switch(self){
        case .autolock:
            return LocalString._auto_lock
        case .language:
            return LocalString._app_language
        case .combinContacts:
            return LocalString._combined_contacts
        case .cleanCache:
            return LocalString._local_cache_management
        case .push:
            return LocalString._push_notification
        case .browser:
            return LocalString._default_browser
        }
    }
}


protocol SettingsDeviceViewModel : AnyObject {
    var sections: [SettingDeviceSection] { get set }
    
    var appSettigns: [DeviceSectionItem] { get set }
    
    var networkItems : [SNetworkItems] {get set }
    
    func appVersion() -> String
    
    var userManager: UserManager { get }
    
    var email : String { get }
    var name : String { get }
    
    var languages : [ELanguage] { get }
    
    var lockOn : Bool { get }
    var combineContactOn: Bool { get }
}

class SettingsDeviceViewModelImpl : SettingsDeviceViewModel {
    var sections: [SettingDeviceSection] = [ .account, .app, .network, .info]
    
    var appSettigns: [DeviceSectionItem] = [.push, .autolock, .language, .combinContacts, .browser, .cleanCache]
    var networkItems : [SNetworkItems] = [.doh]
    var userManager: UserManager
    var lockOn : Bool {
        return userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled
    }
    var combineContactOn: Bool {
        return userCachedStatus.isCombineContactOn
    }
    init(user : UserManager) {
        self.userManager = user
    }
    
    var languages: [ELanguage] = ELanguage.allItems()
    
    
    func appVersion() -> String {
        var appVersion = "Unkonw Version"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = "\(version)"
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            appVersion = appVersion + " (\(build))"
        }
        return appVersion
    }
    
    var email : String {
        get {
            return self.userManager.defaultEmail
        }
    }
    
    var name : String {
        get {
            return self.userManager.defaultDisplayName
        }
    }
}
