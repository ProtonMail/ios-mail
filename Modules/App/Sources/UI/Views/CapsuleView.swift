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

struct CapsuleView: View {
    let text: LocalizedStringResource
    let color: Color
    let icon: Image?
    let iconColor: Color?
    let style: CapsuleStyle

    init(
        text: LocalizedStringResource,
        color: Color,
        icon: Image? = nil,
        iconColor: Color? = nil,
        style: CapsuleStyle
    ) {
        self.text = text
        self.color = color
        self.icon = icon
        self.iconColor = iconColor
        self.style = style
    }

    var body: some View {
        HStack(spacing: DS.Spacing.small) {
            if let icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .square(size: 14)
                    .foregroundColor(iconColor ?? DS.Color.Icon.weak)
            }
            Text(text)
                .font(.caption2)
                .fontWeight(style.fontWeight)
                .foregroundColor(style.fontColor)
                .lineLimit(1)
                .frame(minWidth: 30)

        }
        .padding(EdgeInsets(top: DS.Spacing.small, leading: DS.Spacing.standard, bottom: DS.Spacing.small, trailing: DS.Spacing.standard))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .foregroundColor(color)
        )
    }
}

struct CapsuleStyle {
    let fontColor: Color
    let fontWeight: Font.Weight

    static let attachment: CapsuleStyle = {
        .init(fontColor: DS.Color.Text.norm, fontWeight: .regular)
    }()

    static let label: CapsuleStyle = {
        .init(fontColor: .white, fontWeight: .semibold)
    }()

}

#Preview {
    VStack {
        CapsuleView(text: "".notLocalized.stringResource, color: DS.Color.Background.secondary, style: .attachment)
        CapsuleView(text: "2 files".notLocalized.stringResource, color: DS.Color.Background.secondary, icon: Image(DS.Icon.icPaperClip), style: .attachment)
        CapsuleView(text: "games".notLocalized.stringResource, color: DS.Color.Background.secondary, icon: Image(systemName: "gamecontroller"), style: .attachment)
        CapsuleView(text: "Work".notLocalized.stringResource, color: .blue, style: .label)
        CapsuleView(text: "Friends & Fam".notLocalized.stringResource, color: .pink, style: .label)
    }
}
