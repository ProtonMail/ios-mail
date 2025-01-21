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

import SwiftUI
import InboxDesignSystem

struct SendingTag: View {

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.compact) {
            Image(DS.Icon.icPaperPlane)
                .resizable()
                .square(size: 14)
                .foregroundStyle(DS.Color.Notification.success)
            Text("Sending..".notLocalized) // FIXME: - Localize
                .foregroundStyle(DS.Color.Notification.success)
                .font(.caption)
        }
        .padding(.horizontal, DS.Spacing.standard)
        .padding(.vertical, DS.Spacing.compact)
        .overlay {
            Capsule()
                .stroke(DS.Color.Notification.success, lineWidth: 1)
        }
    }

}

#Preview {
    ZStack(alignment: .center, content: {
        SendingTag()
    })
}
