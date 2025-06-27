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

public struct ActionSheetButton<Content: View>: View {
    let displayBottomSeparator: Bool
    let action: () -> Void
    let content: () -> Content

    public init(displayBottomSeparator: Bool, action: @escaping () -> Void, content: @escaping () -> Content) {
        self.displayBottomSeparator = displayBottomSeparator
        self.action = action
        self.content = content
    }

    public var body: some View {
        VStack(spacing: .zero) {
            Button(action: action) {
                content()
                    .frame(height: 52)
                    .padding(.leading, DS.Spacing.large)
            }
            .buttonStyle(RegularButtonStyle())

            if displayBottomSeparator {
                Divider()
                    .frame(height: 1)
                    .background(DS.Color.BackgroundInverted.border)
            }
        }
    }
}
