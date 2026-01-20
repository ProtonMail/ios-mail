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
import InboxDesignSystem
import SwiftUI

public struct PrivacyInfoSheet<Content: View>: View {
    private let content: () -> Content
    private let dismiss: () -> Void

    public init(content: @escaping () -> Content, dismiss: @escaping () -> Void) {
        self.content = content
        self.dismiss = dismiss
    }

    public var body: some View {
        VStack(spacing: .zero) {
            ScrollView {
                content()
                    .padding(.horizontal, DS.Spacing.extraLarge)
            }
            .scrollClipDisabled()

            ZStack {
                LinearGradient.fading
                    .edgesIgnoringSafeArea(.all)

                Button(action: { dismiss() }) {
                    Text(CommonL10n.gotIt)
                }
                .buttonStyle(BigButtonStyle())
                .padding(.bottom, DS.Spacing.huge)
                .padding([.horizontal, .top], DS.Spacing.extraLarge)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, DS.Spacing.huge)
        .background(DS.Color.BackgroundInverted.norm)
        .presentationDragIndicator(.visible)
    }
}

private extension LinearGradient {
    static var fading: Self {
        .init(
            colors: [DS.Color.BackgroundInverted.norm.opacity(0.2), DS.Color.BackgroundInverted.norm],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
