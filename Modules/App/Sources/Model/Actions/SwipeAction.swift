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
import proton_app_uniffi
import SwiftUI

extension AssignedSwipeAction {

    func icon(isRead: Bool, isStarred: Bool) -> Image {
        switch self {
        case .noAction:
            DS.Icon.icCrossCircle.image
        case .moveTo(.moveToSystemLabel(let systemLabel, _)):
            systemLabel.icon
        case .moveTo:
            DS.Icon.icFolderArrowIn.image
        case .labelAs:
            DS.Icon.icTag.image
        case .toggleStar:
            Image(symbol: isStarred ? .star : .starSlash)
        case .toggleRead:
            isRead ? DS.Icon.icEnvelopeDot.image : DS.Icon.icEnvelopeOpen.image
        }
    }

    var color: Color {
        switch self {
        case .moveTo(.moveToSystemLabel(label: .trash, _)):
            DS.Color.Notification.error
        case .labelAs, .noAction, .moveTo:
            DS.Color.Icon.hint
        case .toggleStar:
            DS.Color.Notification.warning
        case .toggleRead:
            DS.Color.Brand.norm
        }
    }
}
