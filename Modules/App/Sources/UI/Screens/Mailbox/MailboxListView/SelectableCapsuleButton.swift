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

struct SelectableCapsuleButton<Label: View>: View {
    @ScaledMetric var scale: CGFloat = 1

    let isSelected: Bool
    let action: () -> Void
    let label: () -> Label

    init(
        isSelected: Bool,
        action: @escaping () -> Void,
        label: @escaping () -> Label
    ) {
        self.isSelected = isSelected
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.small) {
                label()

                if isSelected {
                    Image(symbol: .xmark)
                        .foregroundStyle(DS.Color.Brand.plus30)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeIn(duration: 0.1), value: isSelected)
            .font(.footnote)
            .foregroundStyle(isSelected ? DS.Color.Brand.plus30 : DS.Color.Text.norm)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium * scale)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .fill(isSelected ? DS.Color.InteractionBrandWeak.norm : DS.Color.Background.norm)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .stroke(isSelected ? .clear : DS.Color.Border.norm)
        }
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }

}
