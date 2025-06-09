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

struct FormBigButtonContent: View {
    let title: LocalizedStringResource
    let value: String
    let hasAccentTextColor: Bool
    let symbol: DS.SFSymbol?

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
                Text(value)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(hasAccentTextColor ? DS.Color.Text.accent : DS.Color.Text.norm)
            }
            if let symbol {
                Spacer(minLength: DS.Spacing.small)
                Image(symbol: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.Text.hint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.large)
        .contentShape(Rectangle())
    }
}
