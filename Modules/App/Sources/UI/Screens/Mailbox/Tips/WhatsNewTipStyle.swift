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
import ProtonUIFoundations
import SwiftUI
import TipKit

struct WhatsNewTipStyle: TipViewStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let image = configuration.image {
                image
                    .resizable()
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Icon.accent)
                    .padding(DS.Spacing.compact)
                    .background(DS.Color.InteractionBrandWeak.norm)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
            }

            VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                configuration.title
                    .foregroundStyle(DS.Color.Text.norm)
                    .fontWeight(.semibold)
                    .font(.footnote)

                if let message = configuration.message {
                    message
                        .foregroundStyle(DS.Color.Text.weak)
                        .font(.footnote)
                        .frame(idealWidth: iOS18 ? 300 : .zero)
                }
            }

            CloseButton(
                size: iOS18 ? 18 : 24,
                action: {
                    configuration.tip.invalidate(reason: .tipClosed)
                })
        }
        .padding(DS.Spacing.medium)
        .background(DS.Color.Background.norm)
    }

}

private var iOS18: Bool {
    if #available(iOS 18, *) {
        if #unavailable(iOS 26) {
            return true
        }
    }
    return false
}
