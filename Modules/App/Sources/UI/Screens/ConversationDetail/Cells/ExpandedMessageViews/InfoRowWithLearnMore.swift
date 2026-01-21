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

struct InfoRowWithLearnMore<IconView: View>: View {
    let title: String
    @ViewBuilder let iconView: IconView
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.compact) {
            iconView
                .font(.footnote)
                .foregroundStyle(iconColor)
                .redactable()

            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.norm)
                    .fixedSize(horizontal: false, vertical: true)
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

struct InfoRowWithLearnMorePlaceholder: View {
    var body: some View {
        InfoRowWithLearnMore(
            title: .randomPlaceholder(length: 24),
            iconView: {
                Image(DS.Icon.icLock)
                    .size(.footnote)
            },
            iconColor: .black,
            action: {}
        )
    }
}

extension String {
    static func randomPlaceholder(length: Int) -> String {
        String(Array(repeating: .enSpace, count: length)).notLocalized
    }
}

private extension Character {
    /// Unicode EN SPACE character (U+2002).
    ///
    /// Wider and more consistent than a regular space,
    /// useful for placeholder and redacted text.
    static var enSpace: Character {
        "\u{2002}"
    }
}
