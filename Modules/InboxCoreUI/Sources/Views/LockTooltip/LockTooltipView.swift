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
import proton_app_uniffi

public struct LockTooltipView: View {
    let lock: PrivacyLock
    @Environment(\.dismiss) var dismiss

    public init(lock: PrivacyLock) {
        self.lock = lock
    }

    public var body: some View {
        PrivacyInfoSheet {
            VStack(alignment: .leading, spacing: .zero) {
                Image(lock.icon.displayIcon)
                    .resizable()
                    .foregroundStyle(lock.color.displayColor)
                    .square(size: 32)
                    .padding(.all, DS.Spacing.large)
                    .background(DS.Color.Background.deep)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
                Text(lock.tooltip.displayData.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DS.Color.Text.norm)
                    .padding(.top, DS.Spacing.large)
                VStack(alignment: .leading, spacing: DS.Spacing.huge) {
                    descriptionLabel(lock.tooltip.displayData.description)
                    if let additionalDescription = lock.tooltip.displayData.additionalDescription {
                        descriptionLabel(additionalDescription)
                    }
                }
                .padding(.top, DS.Spacing.medium)
            }
        } dismiss: {
            dismiss.callAsFunction()
        }
    }

    private func descriptionLabel(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .foregroundStyle(DS.Color.Text.weak)
            .tint(DS.Color.Text.accent)
    }
}

#Preview {
    VStack {
        LockTooltipView(lock: .init(icon: .closedLock, color: .green, tooltip: .receiveE2e))
        Spacer()
    }
}
