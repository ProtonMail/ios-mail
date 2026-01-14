// Copyright (c) 2026 Proton Technologies AG
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

import InboxCore
import InboxDesignSystem
import SwiftUI

struct InfoRowWithLearnMore: View {
    let title: String
    let icon: ImageResource
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.compact) {
            Image(icon)
                .resizable()
                .square(size: 14)
                .foregroundStyle(iconColor)
                .redactable()

            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.norm)
                    .redactable()
                Button(action: action) {
                    Text(CommonL10n.learnMore)
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.accent)
                        .redactable()
                }
            }
        }
    }
}

extension InfoRowWithLearnMore {
    static var placeholder: some View {
        Self.init(
            title: "PGP end-to-end encrypted".notLocalized,
            icon: DS.Icon.icLock,
            iconColor: .black,
            action: {}
        )
    }
}
