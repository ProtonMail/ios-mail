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

import DesignSystem
import SwiftUI

struct OnboardingPageView: View {
    let model: OnboardingPage

    var body: some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Image(model.image)
                .aspectRatio(1.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
            texts(title: model.title, subtitle: model.subtitle)
        }
        .padding(.horizontal, DS.Spacing.large)
    }

    private func texts(title: LocalizedStringResource, subtitle: LocalizedStringResource) -> some View {
        VStack(spacing: DS.Spacing.small) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.norm)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .fontBody3()
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
