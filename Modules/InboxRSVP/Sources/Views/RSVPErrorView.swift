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

struct RSVPErrorView: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: DS.Spacing.extraLarge) {
            Image(DS.Images.rsvpError)
                .square(size: 128)
            errorDetails()
            retryButton()
        }
        .padding(.vertical, DS.Spacing.huge)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .cardStyle()
    }

    // MARK: - Private

    @ViewBuilder
    private func errorDetails() -> some View {
        VStack(alignment: .center, spacing: DS.Spacing.mediumLight) {
            Text(L10n.Error.title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.norm)
                .multilineTextAlignment(.center)
            Text(L10n.Error.subtitle)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func retryButton() -> some View {
        Button(L10n.Error.retryButtonTitle.string, action: action)
            .buttonStyle(RSVPButtonStyle.retryButtonStyle)
    }
}

#Preview {
    RSVPErrorView(action: {})
}
