// Copyright (c) 2022 Proton AG
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
import ProtonCore_UIFoundations

final class UndoSendSettingViewModel: SettingsSingleCheckMarkVMProtocol {

    let title = LocalString._account_settings_undo_send_row_title
    let sectionNumber: Int = 1
    let rowNumber: Int = 4
    let headerHeight: CGFloat = 32
    let headerTopPadding: CGFloat = 0
    let footerTopPadding: CGFloat = 8

    private let seconds = [0, 5, 10, 20]
    private var titleArray: [String]
    private var delaySeconds: Int
    private weak var user: UserManager?
    private weak var uiDelegate: SettingsSingleCheckMarkUIProtocol?

    init(user: UserManager, delaySeconds: Int) {
        self.delaySeconds = delaySeconds
        self.user = user

        let localized = LocalString._undo_send_seconds_options
        self.titleArray = self.seconds.map { num -> String in
            return num == 0 ? LocalString._general_disabled_action: String(format: localized, num)
        }
    }

    func set(uiDelegate: SettingsSingleCheckMarkUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func sectionHeader(of section: Int) -> NSAttributedString? {
        nil
    }

    func sectionFooter(of section: Int) -> NSAttributedString? {
        let style = FontManager.CaptionWeak
        return LocalString._undo_send_description.apply(style: style)
    }

    func cellTitle(of indexPath: IndexPath) -> String? {
        return self.titleArray[safe: indexPath.row]
    }

    func cellShouldShowSelection(of indexPath: IndexPath) -> Bool {
        guard let cellSecond = self.seconds[safe: indexPath.row] else {
            return false
        }
        return self.delaySeconds == cellSecond
    }

    func selectItem(indexPath: IndexPath) {
        guard let currentUser = self.user,
              let cellSecond = self.seconds[safe: indexPath.row],
              cellSecond != self.delaySeconds else {
            return
        }
        self.uiDelegate?.showLoading(shouldShow: true)
        currentUser
            .userService
            .updateDelaySeconds(userInfo: currentUser.userInfo,
                                delaySeconds: cellSecond) { [weak self] _, _, error in
                DispatchQueue.main.async {
                    self?.uiDelegate?.showLoading(shouldShow: false)
                    if let error = error {
                        self?.uiDelegate?.show(error: error.localizedDescription)
                    } else {
                        self?.user?.save()
                        self?.uiDelegate?.reloadTable()
                        self?.delaySeconds = cellSecond
                    }
                }
            }
    }
}
