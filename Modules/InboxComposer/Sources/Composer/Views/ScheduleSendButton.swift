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

struct ScheduleSendButton: View {
    @Environment(\.isEnabled) var isEnabled
    let onTap: () -> Void

    private var iconColor: Color {
        isEnabled ? DS.Color.InteractionBrand.norm : DS.Color.InteractionBrand.disabled
    }

    var body: some View {
        Button(
            action: onTap,
            label: {
                Image(DS.Icon.icClockPaperPlane)
                    .resizable()
                    .square(size: 24)
                    .foregroundStyle(iconColor)
            }
        )
        .square(size: 40)
    }
}
