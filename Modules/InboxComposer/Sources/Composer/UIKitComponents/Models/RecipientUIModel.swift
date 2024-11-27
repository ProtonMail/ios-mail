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
import UIKit
import struct SwiftUI.Color

struct RecipientUIModel: Equatable {
    let type: RecipientType
    let address: String
    var isSelected: Bool
    let isValid: Bool
    let isEncrypted: Bool

    var backgroundColor: UIColor {
        UIColor(isSelected ? DS.Color.InteractionWeak.pressed : DS.Color.Background.norm)
    }

    var icon: UIImage? {
        guard isValid else { return UIImage(resource: DS.Icon.icExclamationCircle) }
        switch type {
        case .single:
            return isEncrypted ? UIImage(resource: DS.Icon.icLockFilled) : nil
        case .group:
            return UIImage(resource: DS.Icon.icUsersFilled)
        }
    }

    // FIXME: WIP - pending lock icon colors states and color definition
    var iconTintColor: UIColor {
        guard isValid else { return UIColor(DS.Color.Notification.error) }
        if type == .group {
            return UIColor(DS.Color.Notification.success)
        }
        return UIColor(Color(hex: "#239ECE"))
    }

    var textColor: UIColor {
        guard isValid else { return UIColor(DS.Color.Notification.error) }
        return UIColor(DS.Color.Text.norm)
    }

    var borderColor: UIColor {
        guard isValid else { return UIColor(DS.Color.Notification.error) }
        return UIColor(DS.Color.Border.norm)
    }
}

enum RecipientType {
    case single
    case group
}

extension Array where Element == RecipientUIModel {

    var noneIsSelected: Bool {
        filter(\.isSelected).isEmpty
    }
}
