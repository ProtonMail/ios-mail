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

import DesignSystem
import SwiftUI

struct ActionSheetSelectableColorButton: View {
    let displayData: ActionColorButtonDisplayData
    let displayBottomSeparator: Bool
    let action: () -> Void

    var body: some View {
        ActionSheetButton(displayBottomSeparator: displayBottomSeparator, action: action) {
            HStack(spacing: DS.Spacing.large) {
                displayData.color
                    .square(size: 13)
                    .clipShape(Circle())
                    .square(size: 20)
                Text(displayData.title)
                    .foregroundStyle(DS.Color.Text.weak)
                Spacer()

                if let image = displayData.isSelected.image {
                    Image(image)
                        .resizable()
                        .square(size: 24)
                        .padding(.trailing, DS.Spacing.moderatelyLarge)
                        .foregroundStyle(DS.Color.Icon.accent)
                }
            }
        }
    }
}
