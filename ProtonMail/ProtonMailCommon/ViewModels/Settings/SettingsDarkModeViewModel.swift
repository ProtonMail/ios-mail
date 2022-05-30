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

class SettingsDarkModeViewModel {
    private(set) var darkModeCache: DarkModeCacheProtocol

    init(darkModeCache: DarkModeCacheProtocol) {
        self.darkModeCache = darkModeCache
    }

    func getCellTitle(of indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else {
            return nil
        }
        switch indexPath.row {
        case 0:
            return DarkModeStatus.followSystem.titleOfSetting
        case 1:
            return DarkModeStatus.forceOn.titleOfSetting
        case 2:
            return DarkModeStatus.forceOff.titleOfSetting
        default:
            return nil
        }
    }

    func getCellShouldShowSelection(of indexPath: IndexPath) -> Bool {
        return self.indexPath(for: darkModeCache.darkModeStatus) == indexPath
    }

    func updateDarkModeStatus(to status: DarkModeStatus?) {
        guard let newStatus = status else {
            return
        }
        darkModeCache.darkModeStatus = newStatus
        if #available(iOS 13, *) {
            NotificationCenter.default.post(name: .shouldUpdateUserInterfaceStyle, object: nil)
        }
    }

    func getDarkModeStatus(for indexPath: IndexPath) -> DarkModeStatus? {
        guard indexPath.section == 0 else {
            return nil
        }
        switch indexPath.row {
        case 0:
            return .followSystem
        case 1:
            return .forceOn
        case 2:
            return .forceOff
        default:
            return nil
        }
    }

    func indexPath(for status: DarkModeStatus) -> IndexPath {
        switch status {
        case .followSystem:
            return IndexPath(row: 0, section: 0)
        case .forceOn:
            return IndexPath(row: 1, section: 0)
        case .forceOff:
            return IndexPath(row: 2, section: 0)
        }
    }
}
