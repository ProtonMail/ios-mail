// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum DarkModeStatus: Int {
    case followSystem
    case forceOn
    case forceOff

    var titleOfSetting: String {
        switch self {
        case .followSystem:
            return LocalString._settings_dark_mode_title_follow_system
        case .forceOn:
            return LocalString._settings_dark_mode_title_force_on
        case .forceOff:
            return LocalString._settings_dark_mode_title_force_off
        }
    }
}

protocol DarkModeCacheProtocol {

    var darkModeStatus: DarkModeStatus { get set }
}
