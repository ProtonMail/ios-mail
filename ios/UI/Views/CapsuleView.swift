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

struct CapsuleView: View {
    let text: String
    let color: Color
    let icon: UIImage?
    let style: CapsuleStyle

    private var minWidth: CGFloat? {
        text.isEmpty ? nil : 30
    }

    private var padding: EdgeInsets {
        text.isEmpty
        ? .init(.zero)
        : .init(
            top: DS.Spacing.small,
            leading: DS.Spacing.standard,
            bottom: DS.Spacing.small,
            trailing: DS.Spacing.standard
        )
    }

    var body: some View {
        HStack(spacing: DS.Spacing.small) {
            if let icon {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(DS.Color.Icon.weak)
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
            Capsule()
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
        CapsuleView(text: "", color: DS.Color.Background.secondary, icon: nil, style: .attachment)
        CapsuleView(text: "2 files", color: DS.Color.Background.secondary, icon: DS.Icon.icPaperClip, style: .attachment)
        CapsuleView(text: "Work", color: .blue, icon: nil, style: .label)
        CapsuleView(text: "Friends & Fam", color: .pink, icon: nil, style: .label)
    }
}

