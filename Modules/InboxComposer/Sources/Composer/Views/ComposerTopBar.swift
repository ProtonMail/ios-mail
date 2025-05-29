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

struct ComposerTopBar: View {
    var isSendEnabled: Bool
    var scheduleSendAction: (() -> Void)?
    var sendAction: (() async -> Void)?
    var dismissAction: (() -> Void)?

    var body: some View {
        HStack(spacing: DS.Spacing.standard) {
            Button(action: { dismissAction?() }) {
                Image(symbol: .xmark)
                    .foregroundStyle(DS.Color.Icon.weak)
                    .square(size: Layout.iconSize)
            }
            .square(size: Layout.buttonSize)
            Spacer()
            ScheduleSendButton { scheduleSendAction?() }
                .disabled(!isSendEnabled)
            SendButton { Task { await sendAction?() } }
                .disabled(!isSendEnabled)
        }
        .padding(.leading, DS.Spacing.standard)
        .padding(.top, DS.Spacing.mediumLight)
        .padding(.trailing, DS.Spacing.medium)
        .padding(.bottom, DS.Spacing.small)
    }

    private enum Layout {
        static let iconSize: CGFloat = 24
        static let buttonSize: CGFloat = 40
    }
}

#Preview {
    VStack {
        ComposerTopBar(isSendEnabled: true)
        ComposerTopBar(isSendEnabled: false)
    }
}
