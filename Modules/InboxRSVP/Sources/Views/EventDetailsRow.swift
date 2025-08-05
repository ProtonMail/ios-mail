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

struct EventDetailsRow: View {
    let icon: ImageResource
    let iconColor: Color
    let text: String
    let trailingIconSymbol: DS.SFSymbol?

    init(
        icon: ImageResource,
        iconColor: Color = DS.Color.Text.weak,
        text: String,
        trailingIconSymbol: DS.SFSymbol? = .none
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.text = text
        self.trailingIconSymbol = trailingIconSymbol
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.medium) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(iconColor)
                .square(size: 20)
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
                if let trailingIconSymbol {
                    Image(symbol: trailingIconSymbol)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundStyle(iconColor)
                        .contentTransition(.symbolEffect(.replace.downUp.wholeSymbol, options: .nonRepeating))
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, DS.Spacing.standard)
        .padding(.vertical, DS.Spacing.compact)
    }
}
