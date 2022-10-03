// Copyright (c) 2022 Proton Technologies AG
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
import UIKit

final class DarkModeSettingViewModel: SettingsSingleCheckMarkVMProtocol {
    let title = LocalString._dark_mode
    let sectionNumber = 1
    let rowNumber = 3
    let headerHeight: CGFloat = UITableView.automaticDimension
    let headerTopPadding: CGFloat = 24
    let footerTopPadding: CGFloat = 0
    let options = [
        DarkModeStatus.followSystem,
        DarkModeStatus.forceOn,
        DarkModeStatus.forceOff
    ]

    private(set) var darkModeCache: DarkModeCacheProtocol

    init(darkModeCache: DarkModeCacheProtocol) {
        self.darkModeCache = darkModeCache
    }

    func sectionHeader(of section: Int) -> NSAttributedString? {
        let textAttribute = FontManager.DefaultSmallWeak.alignment(.left)
        return NSAttributedString(string: LocalString._settings_dark_mode_section_title,
                                  attributes: textAttribute)
    }

    func sectionFooter(of section: Int) -> NSAttributedString? {
        nil
    }

    func cellTitle(of indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else { return nil }
        return options[safe: indexPath.row]?.titleOfSetting
    }

    func cellShouldShowSelection(of indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 else { return false }
        switch darkModeCache.darkModeStatus {
        case .followSystem:
            return indexPath.row == 0
        case .forceOn:
            return indexPath.row == 1
        case .forceOff:
            return indexPath.row == 2
        }
    }

    func selectItem(indexPath: IndexPath) {
        guard let newStatus = options[safe: indexPath.row],
              newStatus != darkModeCache.darkModeStatus else { return }
        darkModeCache.darkModeStatus = newStatus
        if #available(iOS 13, *) {
            NotificationCenter.default.post(name: .shouldUpdateUserInterfaceStyle, object: nil)
        }
    }
}
