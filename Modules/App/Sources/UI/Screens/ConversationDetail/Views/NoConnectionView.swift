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

struct NoConnectionView: View {

    var body: some View {
        VStack(spacing: .zero) {
            Image(DS.Images.noConnection)
                .padding(.bottom, DS.Spacing.extraLarge)
            Text(L10n.NoConnection.title)
                .font(.callout)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Color.Text.norm)
                .padding(.bottom, DS.Spacing.mediumLight)
            Text(L10n.NoConnection.subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.Color.Text.weak)
        }
        .frame(width: 295, height: 375, alignment: .center)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        NoConnectionView()
    }
}
