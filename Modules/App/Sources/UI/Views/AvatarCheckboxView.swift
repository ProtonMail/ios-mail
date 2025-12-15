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

import InboxCoreUI
import InboxDesignSystem
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
                        .fill(DS.Color.Brand.norm)
                        .overlay {
                            Image(DS.Icon.icCheckmarkBig)
                                .resizable()
                                .foregroundColor(DS.Color.Icon.inverted)
                                .padding(10)
                                .accessibilityIdentifier(AvatarCheckboxViewIdentifiers.avatarChecked)
                        }
                }
                .accessibilityElement(children: .contain)
            } else {
                AvatarView(avatar: avatar)
            }
        }
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onTapGesture {
            onDidChangeSelection(!isSelected)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack {
        AvatarCheckboxView(
            isSelected: true,
            avatar: .init(
                info: .init(initials: "Mb", color: .cyan),
                type: .sender(.init(params: .init(), blocked: .no))
            )
        ) { _ in }
        .square(size: 40)
        .clipped()

        AvatarCheckboxView(
            isSelected: false,
            avatar: .init(
                info: .init(initials: "Mb", color: .cyan),
                type: .sender(.init(params: .init(), blocked: .no))
            )
        ) { _ in }
        .square(size: 40)
        .clipped()

        AvatarCheckboxView(
            isSelected: false,
            avatar: .init(
                info: .init(initials: "Mb", color: .cyan),
                type: .sender(.init(params: .init(), blocked: .no))
            )
        ) { _ in }
        .square(size: 40)
        .clipped()
    }
}

private struct AvatarCheckboxViewIdentifiers {
    static let avatarChecked = "avatar.checked"
}
