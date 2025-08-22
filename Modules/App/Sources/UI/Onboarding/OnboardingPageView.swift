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

struct OnboardingPageView: View {
    let isLandscapePhone: Bool
    let safeAreaPadding: CGFloat
    let model: OnboardingPage

    var body: some View {
        layout
            .padding(.horizontal, DS.Spacing.huge)
    }

    @ViewBuilder
    private var layout: some View {
        if isLandscapePhone {
            landscapeLayout
                .padding(.horizontal, safeAreaPadding)
                .multilineTextAlignment(.leading)
        } else {
            portraitLayout
                .multilineTextAlignment(.center)
        }
    }

    private var portraitLayout: some View {
        VStack(alignment: .center, spacing: DS.Spacing.extraLarge) {
            image
            texts(title: model.title, subtitle: model.subtitle, alignment: .center)
        }
    }

    private var landscapeLayout: some View {
        HStack(alignment: .center, spacing: DS.Spacing.extraLarge) {
            image
            texts(title: model.title, subtitle: model.subtitle, alignment: .leading)
        }
    }

    private var image: some View {
        Image(model.image)
    }

    private func texts(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: DS.Spacing.small) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.Text.norm)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
