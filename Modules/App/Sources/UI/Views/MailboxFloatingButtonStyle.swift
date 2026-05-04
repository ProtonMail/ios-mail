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

import InboxDesignSystem
import SwiftUI

struct MailboxFloatingButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.all, DS.Spacing.moderatelyLarge)
            .foregroundStyle(isSelected ? DS.Color.Text.inverted : DS.Color.Text.norm)
            .background(isSelected ? DS.Color.InteractionBrand.pressed : DS.Color.InteractionFab.norm)
            .overlay(
                Capsule()
                    .fill(Color.black.opacity(configuration.isPressed ? 0.1 : 0))
                    .stroke(DS.Color.Border.light, lineWidth: 1)
            )
            .clipShape(.capsule)
            .shadow(DS.Shadows.liftedFull, isVisible: true)
    }
}
