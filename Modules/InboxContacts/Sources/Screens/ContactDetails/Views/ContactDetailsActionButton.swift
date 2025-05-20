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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct ContactDetailsActionButton: View {
    let image: ImageResource
    let title: LocalizedStringResource
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.standard) {
                Image(image)
                    .square(size: 24)
                    .foregroundStyle(foregroundColor)
                Text(title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.large)
            .contentShape(Rectangle())
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
        .disabled(disabled)
        .roundedRectangleStyle()
    }

    // MARK: - Private

    private var foregroundColor: Color {
        disabled ? DS.Color.Text.disabled : DS.Color.Text.weak
    }
}
