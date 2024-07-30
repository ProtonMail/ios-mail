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

import DesignSystem
import SwiftUI

struct ProtonOfficialBadgeView: View {

    var body: some View {
        SenderBadgeView(
            color: DS.Color.Brand.lighten30,
            text: L10n.official,
            textColor: DS.Color.Brand.darken10
        )
    }
}

struct SenderBadgeView: View {
    let color: Color
    let text: LocalizedStringResource
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.vertical, DS.Spacing.tiny)
            .padding(.horizontal, DS.Spacing.compact)
            .lineLimit(1)
            .background(
                Capsule()
                    .foregroundColor(color)
            )
    }
}

#Preview {
    ProtonOfficialBadgeView()
}
