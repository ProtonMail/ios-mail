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

import InboxCore
import InboxDesignSystem
import SwiftUI

struct SnoozeUpgradeButton: View {
    private let variant: Variant
    private let action: () -> Void

    init(variant: Variant, action: @escaping () -> Void) {
        self.variant = variant
        self.action = action
    }

    enum Variant {
        case fullLine
        case compact
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, DS.Spacing.large)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(UpgradeButtonStyle())
    }

    @ViewBuilder
    private var content: some View {
        switch variant {
        case .fullLine:
            HStack {
                textContent(alignment: .leading, subtitle: CommonL10n.upsellButtonSubtitle)
                Spacer()
                Image(DS.Icon.icBrandProtonMailUpsell)
            }
            .padding(.vertical, DS.Spacing.moderatelyLarge)
        case .compact:
            VStack(spacing: .zero) {
                Image(DS.Icon.icBrandProtonMailUpsell)

                textContent(alignment: .center, subtitle: L10n.Snooze.smallUpsellButtonSubtitle)
            }
            .padding(.bottom, DS.Spacing.moderatelyLarge)
        }
    }

    private func textContent(alignment: HorizontalAlignment, subtitle: LocalizedStringResource) -> some View {
        VStack(alignment: alignment, spacing: DS.Spacing.small) {
            Text(L10n.Snooze.customButtonTitle)
                .font(.callout)
                .foregroundStyle(DS.Color.Text.norm)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(DS.Color.Text.weak)
        }
    }
}

private struct UpgradeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .fill(configuration.isPressed ? DS.Color.InteractionWeak.pressed : DS.Color.BackgroundInverted.secondary)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: DS.Color.Gradient.crazy),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

#Preview {
    ZStack {
        SnoozeUpgradeButton(variant: .compact) {}
            .padding()
    }
}
