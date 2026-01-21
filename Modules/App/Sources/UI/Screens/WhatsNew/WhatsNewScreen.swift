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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct WhatsNewScreen: View {
    @Environment(\.dismiss) var dismiss
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var body: some View {
        ScrollWithBottomButton {
            VStack(spacing: .zero) {
                Image(DS.Images.whatsNewCelebration)
                    .padding(.top, 90)

                Text(L10n.WhatsNew.version(version: bundle.bundleShortVersion))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(DS.Color.Text.weak)
                    .padding(.top, 48)

                Text(L10n.WhatsNew.title)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.title.bold())
                    .padding(.top, DS.Spacing.standard)

                VStack(alignment: .leading, spacing: .zero) {
                    ForEach(NewFeatureIntroduction.whatsNew, id: \.self) { feature in
                        HStack(alignment: .top, spacing: DS.Spacing.medium) {
                            Image(feature.icon)
                                .size(.subheadline)
                                .foregroundStyle(DS.Color.Icon.norm)
                                .padding(DS.Spacing.standard)
                                .background(DS.Color.Background.deep)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Spacing.mediumLight))

                            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                                Text(feature.name)
                                    .foregroundStyle(DS.Color.Text.norm)
                                    .font(.subheadline.weight(.semibold))

                                Text(feature.description)
                                    .foregroundStyle(DS.Color.Text.norm)
                                    .font(.footnote)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.standard)
                        .padding(.vertical, DS.Spacing.large)
                    }
                }
                .padding(.top, DS.Spacing.extraLarge)
                .frame(maxWidth: .infinity)
            }
        } dismiss: {
            dismiss()
        }
    }
}

#Preview {
    WhatsNewScreen()
}
