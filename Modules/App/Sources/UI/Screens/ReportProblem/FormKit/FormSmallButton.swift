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

struct FormSmallButton: View {
    private let title: LocalizedStringResource
    private let additionalInfo: LocalizedStringResource?
    private let action: () -> Void

    init(
        title: LocalizedStringResource,
        additionalInfo: LocalizedStringResource?,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.additionalInfo = additionalInfo
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            Button(action: { action() }) {
                HStack {
                    Text(title)
                    Spacer(minLength: DS.Spacing.medium)
                    Image(systemName: "chevron.right")
                }
                .padding(.vertical, DS.Spacing.moderatelyLarge)
                .padding(.horizontal, DS.Spacing.large)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsButtonStyle())
            .applyRoundedRectangleStyle()

            if let additionalInfo {
                FormFootnoteText(additionalInfo)
                    .padding(.horizontal, DS.Spacing.large)
            }
        }
    }
}
