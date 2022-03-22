//
//  ActionSheetPresentProtocol.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations

extension UIViewController {
    func showDiscardAlert(handleDiscard: @escaping () -> Void) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._discard_changes_title,
                                      preferredStyle: .alert)
        let discard = UIAlertAction(title: LocalString._general_discard, style: .destructive) { _ in
            handleDiscard()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [discard, cancelAction].forEach(alert.addAction)
        self.navigationController?.present(alert, animated: true, completion: nil)
    }

    func dismissActionSheet() {
        let actionSheet = navigationController?
            .view.subviews.compactMap { $0 as? PMActionSheet }.last
        actionSheet?.dismiss(animated: true)
    }
}
