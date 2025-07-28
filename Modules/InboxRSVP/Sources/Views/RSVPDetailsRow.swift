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

struct RSVPDetailsRow: View {
    let icon: ImageResource
    let iconColor: Color
    let iconSize: CGFloat
    let text: String
    let trailingIcon: ImageResource?

    init(
        icon: ImageResource,
        iconColor: Color = DS.Color.Text.weak,
        iconSize: CGFloat = 18.0,
        text: String,
        trailingIcon: ImageResource? = .none
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.text = text
        self.trailingIcon = trailingIcon
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.medium) {
            Image(icon)
                .foregroundStyle(iconColor)
                .square(size: iconSize)
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
                if let trailingIcon {
                    Image(trailingIcon)
                        .foregroundStyle(iconColor)
                        .square(size: 16)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.all, DS.Spacing.standard)
    }
}
