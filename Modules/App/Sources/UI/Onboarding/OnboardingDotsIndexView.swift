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

struct OnboardingDotsIndexView: View {
    let pagesCount: Int
    let selectedPageIndex: Int
    let onTap: (_ pageIndex: Int) -> Void

    // MARK: - View

    var body: some View {
        HStack(spacing: DS.Spacing.small) {
            ForEach(0..<pagesCount, id: \.self) { pageIndex in
                RoundedRectangle(cornerRadius: DS.Radius.massive)
                    .fill(color(forIndex: pageIndex))
                    .frame(width: width(forIndex: pageIndex), height: dotSize)
                    .animation(.easeInOut, value: selectedPageIndex)
                    .onTapGesture { onTap(pageIndex) }
                    .id(pageIndex)
            }
        }
    }

    // MARK: - Private

    private let dotSize: CGFloat = 4

    private func color(forIndex index: Int) -> Color {
        selectedPageIndex == index ? DS.Color.InteractionBrand.norm : DS.Color.Shade.shade40
    }

    private func width(forIndex index: Int) -> CGFloat {
        selectedPageIndex == index ? dotSize * 4 : dotSize
    }
}
