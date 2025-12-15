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

import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

extension ExclusiveLocation {
    var selectedMailbox: SelectedMailbox {
        switch self {
        case .system(let name, let id):
            return .systemFolder(labelId: id, systemFolder: name)
        case .custom(let name, let id, _):
            return .customFolder(labelId: id, name: name.stringResource)
        }
    }

    var mailboxLocationIcon: Image {
        switch self {
        case .system(let systemLabel, _):
            systemLabel.icon
        case .custom:
            DS.Icon.icFolder.image
        }
    }

    var model: MessageDetail.Location {
        switch self {
        case .system(let systemLabel, let id):
            .init(id: id, name: systemLabel.humanReadable, icon: systemLabel.icon, iconColor: nil)
        case .custom(let name, let id, let color):
            .init(
                id: id,
                name: name.stringResource,
                icon: DS.Icon.icFolderOpenFilled.image,
                iconColor: Color(hex: color.value)
            )
        }
    }
}
