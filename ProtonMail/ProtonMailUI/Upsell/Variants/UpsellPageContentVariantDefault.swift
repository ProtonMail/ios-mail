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

import ProtonCoreUIFoundations
import SwiftUI

struct UpsellPageContentVariantDefault: View {
    let perks: [UpsellPageModel.Perk]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(perks.indices, id: \.self) { idx in
                VStack(alignment: .leading) {
                    HStack(spacing: 12) {
                        IconProvider[dynamicMember: perks[idx].icon]
                            .frame(maxHeight: 20)
                            .foregroundColor(ColorProvider.IconWeak)
                            .preferredColorScheme(.dark)

                        Text(perks[idx].description)
                            .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                            .foregroundColor(ColorProvider.SidebarTextWeak)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if idx != perks.indices.last {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                    }
                }
            }
        }
    }
}
