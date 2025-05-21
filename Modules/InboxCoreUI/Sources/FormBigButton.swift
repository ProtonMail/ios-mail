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

public struct FormBigButton: View {
    private let value: String
    private let title: LocalizedStringResource
    private let systemIconName: String?
    private let action: () -> Void
    private let hasAccentTextColor: Bool

    public init(
        title: LocalizedStringResource,
        icon: String?,
        value: String,
        action: @escaping () -> Void,
        hasAccentTextColor: Bool = false
    ) {
        self.title = title
        self.systemIconName = icon
        self.value = value
        self.action = action
        self.hasAccentTextColor = hasAccentTextColor
    }

    public var body: some View {
        Button(action: action) {
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
                if let systemIconName {
                    Spacer(minLength: DS.Spacing.small)
                    Image(systemName: systemIconName)
                        .font(.system(size: 20))
                        .foregroundStyle(DS.Color.Text.hint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.large)
            .contentShape(Rectangle())
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
    }
}
