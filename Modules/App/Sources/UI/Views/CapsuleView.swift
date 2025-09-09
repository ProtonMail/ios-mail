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

struct CapsuleView: View {
    let text: LocalizedStringResource
    let color: Color
    let style: CapsuleStyle

    init(text: LocalizedStringResource, color: Color, style: CapsuleStyle) {
        self.text = text
        self.color = color
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(style.fontWeight)
            .foregroundColor(.white)
            .padding(.horizontal, DS.Spacing.standard)
            .padding(.vertical, DS.Spacing.small)
            .lineLimit(1)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
    }
}

struct CapsuleStyle {
    let fontWeight: Font.Weight

    static let label = CapsuleStyle(fontWeight: .semibold)
}

#Preview {
    VStack {
        CapsuleView(text: "Work".notLocalized.stringResource, color: .blue, style: .label)
        CapsuleView(text: "Friends & Fam".notLocalized.stringResource, color: .pink, style: .label)
    }
}
