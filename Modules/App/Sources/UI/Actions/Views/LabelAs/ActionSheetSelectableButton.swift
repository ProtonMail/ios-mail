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

struct ActionSheetSelectableButton: View {
    let displayData: ActionSelectableButtonDisplayData
    let displayBottomSeparator: Bool
    let action: () -> Void

    var body: some View {
        ActionSheetButton(displayBottomSeparator: displayBottomSeparator, action: action) {
            HStack(spacing: DS.Spacing.large) {
                visualAsset()
                    .padding(.leading, displayData.leadingSpacing)
                Text(displayData.title)
                    .lineLimit(1)
                    .foregroundStyle(DS.Color.Text.norm)
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

    // MARK: - Private

    @ViewBuilder
    func visualAsset() -> some View {
        switch displayData.visualAsset {
        case .color(let color):
            color
                .square(size: 13)
                .clipShape(Circle())
                .square(size: 20)
        case .image(let imageResource, let color):
            Image(imageResource)
                .resizable()
                .square(size: 20)
                .foregroundStyle(color)
        }
    }
}
