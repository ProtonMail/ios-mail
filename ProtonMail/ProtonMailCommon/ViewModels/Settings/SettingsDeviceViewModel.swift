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
    
    public var description : String {
        switch(self){
        case .account:
            return LocalString._account_settings
        case .app:
            return LocalString._app_settings
        case .info:
            return LocalString._app_information
        }
    }
}

public enum DeviceSectionItem : Int, CustomStringConvertible {
    case autolock = 0
    case language = 1
    case combinContacts = 2
    case cleanCache = 3
    
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
        }
    }
}


protocol SettingsDeviceViewModel : AnyObject {
    var sections: [SettingDeviceSection] { get set }
    
    var appSettigns: [DeviceSectionItem] { get set }
    
    func appVersion() -> String
    
    var userManager: UserManager { get }
    
    var email : String { get }
}

class SettingsDeviceViewModelImpl : SettingsDeviceViewModel {
    var sections: [SettingDeviceSection] = [ .account, .app, .info]
    
    var appSettigns: [DeviceSectionItem] = [.autolock, .language, .combinContacts, .cleanCache]
    var userManager: UserManager
    init(user : UserManager) {
        self.userManager = user
    }
    
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
            return self.userManager.defaultDisplayName
        }
    }
}
