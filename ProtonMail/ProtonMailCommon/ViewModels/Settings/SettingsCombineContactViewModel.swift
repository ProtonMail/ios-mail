//
//  SettingsCombineContactViewModel.swift
//  ProtonMail - Created on 2020/4/27.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

class SettingsCombineContactViewModel {
    enum SettingSection: Int {
        case combineContact = 0

        var title: String {
            switch self {
            case .combineContact:
                return LocalString._settings_title_of_combined_contact
            }
        }

        var foot: String {
            switch self {
            case .combineContact:
                return LocalString._settings_footer_of_combined_contact
            }
        }
    }

    private var combineContactCache: ContactCombinedCacheProtocol

    init(combineContactCache: ContactCombinedCacheProtocol) {
        self.combineContactCache = combineContactCache
    }

    var isContactCombined: Bool {
        get {
            return combineContactCache.isCombineContactOn
        }
        set {
            combineContactCache.isCombineContactOn = newValue
        }
    }

    var sections: [SettingSection] = [.combineContact]
}
