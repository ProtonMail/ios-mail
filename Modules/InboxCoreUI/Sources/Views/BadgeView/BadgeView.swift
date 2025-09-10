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

struct BadgeView: View {
    let text: String
    let color: Color

    init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, DS.Spacing.small)
            .padding(.horizontal, DS.Spacing.standard)
            .lineLimit(1)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
    }
}

#Preview {
    VStack {
        BadgeView(text: "Work".notLocalized, color: .blue)
        BadgeView(text: "Friends & Fam".notLocalized, color: .pink)
    }
}
