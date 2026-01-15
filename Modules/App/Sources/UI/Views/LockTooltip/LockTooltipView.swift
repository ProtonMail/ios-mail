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

struct LockTooltipView: View {
    let lock: PrivacyLock
    @Environment(\.dismiss) var dismiss

    init(lock: PrivacyLock) {
        self.lock = lock
    }

    var body: some View {
        VStack(spacing: .zero) {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    Image(lock.icon.displayIcon)
                        .resizable()
                        .foregroundStyle(lock.color.displayColor)
                        .square(size: 32)
                        .padding(.all, DS.Spacing.large)
                        .background(DS.Color.Background.deep)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
                    Text(lock.tooltip.displayData.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DS.Color.Text.norm)
                        .padding(.top, DS.Spacing.large)
                    VStack(alignment: .leading, spacing: DS.Spacing.huge) {
                        Text(lock.tooltip.displayData.description)
                            .foregroundStyle(DS.Color.Text.weak)
                            .tint(DS.Color.Text.accent)
                            .padding(.top, DS.Spacing.medium)
                        if let additionalDescription = lock.tooltip.displayData.additionalDescription {
                            Text(additionalDescription)
                                .foregroundStyle(DS.Color.Text.weak)
                                .tint(DS.Color.Text.accent)
                                .padding(.top, DS.Spacing.medium)
                        }
                    }
                }
            }
            .scrollClipDisabled()
            .padding(.horizontal, DS.Spacing.extraLarge)

            ZStack {
                LinearGradient.fading
                    .edgesIgnoringSafeArea(.all)

                Button(action: { dismiss.callAsFunction() }) {
                    Text(CommonL10n.gotIt)
                }
                .buttonStyle(BigButtonStyle())
                .padding(.bottom, DS.Spacing.standard)
                .padding([.horizontal, .top], DS.Spacing.extraLarge)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, DS.Spacing.huge)
        .presentationDetents([.medium, .large])
        .background(DS.Color.Background.norm)
    }
}

#Preview {
    VStack {
        LockTooltipView(lock: .init(icon: .closedLock, color: .green, tooltip: .receiveE2e))
        Spacer()
    }
}

private extension LinearGradient {
    static var fading: Self {
        .init(
            colors: [DS.Color.Background.norm.opacity(0.2), DS.Color.Background.norm],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
