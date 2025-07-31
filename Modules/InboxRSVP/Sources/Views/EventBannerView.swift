// Copyright (c) 2025 Proton Technologies AG
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

struct EventBannerView: View {
    enum Style: Equatable {
        case now
        case ended
        case cancelled
        case generic

        var color: (text: Color, background: Color) {
            switch self {
            case .now:
                (DS.Color.Notification.success900, DS.Color.Notification.success100)
            case .ended:
                (DS.Color.Notification.warning900, DS.Color.Notification.warning100)
            case .cancelled:
                (DS.Color.Notification.error900, DS.Color.Notification.error100)
            case .generic:
                (DS.Color.Text.norm, DS.Color.Background.deep)
            }
        }
    }

    let style: Style
    let regular: LocalizedStringResource
    let bold: LocalizedStringResource

    var body: some View {
        (Text(regular) + Text(bold).fontWeight(.bold))
            .font(.subheadline)
            .foregroundStyle(style.color.text)
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .padding(.horizontal, DS.Spacing.extraLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.color.background)
    }
}
