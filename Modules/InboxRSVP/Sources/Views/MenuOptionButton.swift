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

struct MenuOptionButton: View {
    let text: LocalizedStringResource
    let action: () -> Void
    let trailingIcon: ImageResource?

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.tiny) {
                Text(text)
                    .font(.callout)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                if let trailingIcon {
                    Image(trailingIcon)
                        .foregroundStyle(DS.Color.Icon.norm)
                        .square(size: 20)
                }
            }
            .padding(.vertical, DS.Spacing.medium)
            .padding(.horizontal, DS.Spacing.large)
        }
    }
}
