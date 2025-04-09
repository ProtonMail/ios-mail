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

struct BannerButton: View {
    let model: Banner.Button
    let style: Banner.ButtonStyle
    let maxWidth: CGFloat?
    
    init(model: Banner.Button, style: Banner.ButtonStyle, maxWidth: CGFloat?) {
        self.model = model
        self.style = style
        self.maxWidth = maxWidth
    }
    
    var body: some View {
        Button(
            action: model.action,
            label: {
                Text(model.title)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(style.text)
                    .frame(maxWidth: maxWidth)
                    .padding(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
                    .background(style.background, in: Capsule())
            }
        )
    }
}
