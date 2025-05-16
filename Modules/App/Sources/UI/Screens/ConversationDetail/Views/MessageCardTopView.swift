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

struct MessageCardTopView: View {
    let cornerRadius: CGFloat
    let hasShadow: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
            .trim(from: 0.5, to: 1.0)
            .stroke(DS.Color.Border.norm, lineWidth: 1)
            .shadow(color: hasShadow ? DS.Color.Shade.shade10 : .clear, radius: 1, x: 0, y: -2)
            .frame(maxHeight: 2 * cornerRadius)
    }
}

#Preview {
    MessageCardTopView(cornerRadius: 40, hasShadow: true)
}
