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

struct FormBigButton: View {
    private let value: LocalizedStringResource
    private let title: LocalizedStringResource
    private let icon: String
    private let action: () -> Void

    init(title: LocalizedStringResource, icon: String, value: LocalizedStringResource, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.value = value
        self.action = action
    }

    var body: some View {
        Button(action: { action() }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.Text.weak)
                    Text(value)
                        .foregroundStyle(DS.Color.Text.norm)
                }
                Spacer(minLength: DS.Spacing.small)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.Text.hint)
            }
            .padding(DS.Spacing.large)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsButtonStyle())
        .applyRoundedRectangleStyle()
    }
}
