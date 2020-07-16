//
//  SettingsCombineContactViewModel.swift
//  ProtonMail - Created on 2020/4/27.
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

enum SettingSction: Int {
    case combineContact = 0
    
    var title: String {
        switch self {
        case .combineContact:
            return "Combined Contacts"
        }
    }
    
    var foot: String {
        switch self {
        case .combineContact:
            return "Turn this feature on to auto-complete email addresses using contacts from all your logged in accounts."
        }
    }
}

class SettingsCombineContactViewModel {
    let users: UsersManager
    
    init(users: UsersManager) {
        self.users = users
    }
    
    var isContactCombined: Bool {
        get {
            return userCachedStatus.isCombineContactOn
        }
        set {
            userCachedStatus.isCombineContactOn = newValue
        }
    }
    
    var sections: [SettingSction] = [.combineContact]
}
