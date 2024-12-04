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

import InboxDesignSystem
import SwiftUI

struct SendButton: View {
    @Environment(\.isEnabled) var isEnabled
    let onTap: () -> Void

    private var textColor: Color {
        isEnabled ? DS.Color.Text.accent : DS.Color.Brand.minus20
    }

    var body: some View {
        Button(action: onTap, label: {
            Text(L10n.Composer.send)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
        })
        .buttonStyle(SendButtonStyle())
    }
}

private struct SendButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func backgroundColor(configuration: Self.Configuration) -> Color {
        if isEnabled {
            configuration.isPressed ? DS.Color.InteractionWeak.pressed : DS.Color.InteractionWeak.norm
        } else {
            DS.Color.InteractionBrandWeak.disabled
        }
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration
            .label
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, DS.Spacing.standard)
            .background(backgroundColor(configuration: configuration))
            .foregroundColor(Color.white)
            .clipShape(Capsule(style: .continuous))
    }
}

#Preview {
    VStack {
        SendButton(onTap: {})
        SendButton(onTap: {}).disabled(true)
    }
}
