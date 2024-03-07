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

struct AvatarCheckboxView: View {
    let isSelected: Bool
    let avatar: AvatarUIModel
    var onDidChangeSelection: ((_ newValue: Bool) -> Void)

    private let cornerRadius = 12.0

    var body: some View {
        ZStack {
            if isSelected {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(DS.Color.backgroundNorm)
                        .stroke(DS.Color.separatorNorm, lineWidth: 1)
                        .overlay {
                            Image(uiImage: DS.Icon.icCheckmark)
                                .resizable()
                                .foregroundColor(DS.Color.iconNorm)
                                .padding(10)
                        }
                }
            } else {
                Text(avatar.initials)
                    .font(.callout)
                    .fontWeight(.regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DS.Color.interactionWeak)
            }
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture {
            onDidChangeSelection(!isSelected)
        }
    }
}

#Preview {
    VStack {
        AvatarCheckboxView(isSelected: true, avatar: .init(initials: "MB")) { _ in}
            .frame(width: 40, height: 40)
            .clipped()

        AvatarCheckboxView(isSelected: false, avatar: .init(initials: "MB")) { _ in}
            .frame(width: 40, height: 40)
            .clipped()
    }
}
