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
import struct SwiftUI.Color
import Foundation

extension Date {

    var toExpirationDateUIModel: ExpirationDateUIModel? {
        guard self > .now else { return nil }

        let components = Calendar.current.dateComponents([.hour, .minute], from: .now, to: self)
        var color: Color = DS.Color.Text.norm
        var isAboutToExpire = false
        if let hours = components.hour, let minute = components.minute {
            color = hours < 1 ? DS.Color.Notification.warning : DS.Color.Text.norm
            isAboutToExpire = hours < 1 && minute < 1
        }

        let text =
            isAboutToExpire
            ? L10n.Mailbox.Item.expiresInLessThanOneMinute
            : L10n.Mailbox.Item.expiresIn(value: self.localisedRemainingTimeFromNow())
        return ExpirationDateUIModel(text: text, color: color)
    }
}
