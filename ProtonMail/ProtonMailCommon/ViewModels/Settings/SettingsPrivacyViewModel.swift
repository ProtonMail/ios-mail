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

public enum SettingPrivacyItem : Int, CustomStringConvertible {
    case autoLoadImage = 0
    case linkOpeningMode = 1
    case browser = 2
    case metadataStripping = 3
    
    public var description : String {
        switch(self){
        case .autoLoadImage:
            return LocalString._auto_show_images
        case .linkOpeningMode:
            return LocalString._request_link_confirmation
        case .metadataStripping:
            return LocalString._strip_metadata
        case .browser:
            return LocalString._default_browser
        }
    }
}

protocol SettingsPrivacyViewModel: AnyObject {
    var privacySections : [SettingPrivacyItem] { get set}
    var userInfo: UserInfo { get }
    var user: UserManager { get }
}

class SettingsPrivacyViewModelImpl: SettingsPrivacyViewModel {   
    
    var privacySections : [SettingPrivacyItem] = [.autoLoadImage, .linkOpeningMode, .metadataStripping]
    let user: UserManager
    
    var userInfo: UserInfo {
        get {
            return self.user.userInfo
        }
    }
    
    init(user: UserManager) {
        self.user = user
    }
}
