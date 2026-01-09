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
import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

// Consider pop-over instead of sheet
struct LockTooltipView: View {
    let lock: PrivacyLock
    @State var contentHeight: CGFloat = .zero

    init(lock: PrivacyLock) {
        self.lock = lock
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    Image(lock.icon.uiIcon)
                        .resizable()
                        .foregroundStyle(lock.color.uiColor)
                        .square(size: 32)
                        .padding(.all, DS.Spacing.large)
                        .background(DS.Color.Background.deep)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
                    Text(lock.tooltip.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DS.Color.Text.norm)
                        .padding(.top, DS.Spacing.large)
                    Text(lock.tooltip.description)
                        .font(.subheadline)
                        .foregroundStyle(DS.Color.Text.weak)
                        .tint(DS.Color.Text.accent)
                        .padding(.top, DS.Spacing.medium)
                    Button(action: {}) {
                        Text(CommonL10n.gotIt)
                    }
                    .buttonStyle(BigButtonStyle())
                    .padding(.top, DS.Spacing.huge)
                }
                .padding(.top, DS.Spacing.mediumLight)
                .padding(.horizontal, DS.Spacing.extraLarge)
                .padding(.bottom, DS.Spacing.huge)
            }
        }
        .presentationDetents([.medium])
        .background(DS.Color.Background.norm)
    }
}

#Preview {
    VStack {
        LockTooltipView(lock: .init(icon: .closedLock, color: .green, tooltip: .receiveE2e))
        Spacer()
    }
}
