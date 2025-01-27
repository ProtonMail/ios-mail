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
import UIKit

enum ContactGroupCellPresenter {
    static func present(item: ContactGroupItem, in cell: ContactGroupCell) {
        cell.labelsView.titleLabel.text = item.name

        cell.labelsView.subtitleLabel.text = L10n.Contacts.groupSubtitle(membersCount: item.contacts.count).string
        cell.labelsView.subtitleLabel.isHidden = item.contacts.isEmpty

        cell.iconBackgroundView.backgroundColor = UIColor(hex: item.avatarColor)
    }
}
