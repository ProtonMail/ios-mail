// Copyright (c) 2024 Proton Technologies AG
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

import proton_app_uniffi
import InboxCoreUI
import UIKit

enum ContactItemCellPresenter {
    static func present(item: ContactItem, in cell: ContactCell) {
        cell.avatarLabel.text = item.avatarInformation.text
        cell.avatarLabel.backgroundColor = UIColor(hex: item.avatarInformation.color)

        cell.labelsView.titleLabel.text = item.name

        cell.labelsView.subtitleLabel.text = item.emails.first?.email
        cell.labelsView.subtitleLabel.isHidden = item.emails.isEmpty
    }
}
