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

import Lottie
import SwiftUI

struct MailboxSkeletonRowView: View {
    let colorScheme: ColorScheme

    // MARK: - View

    var body: some View {
        LottieView(animation: animation(for: colorScheme))
            .playbackInLoopMode()
            .frame(maxWidth: .infinity)
            .frame(height: 40, alignment: .leading)
            .padding(.trailing, 60)
            .styledSkeletonRow()
    }

    // MARK: - Private

    private func animation(for colorScheme: ColorScheme) -> LottieAnimation {
        let darkItem = LottieAnimations.SkeletonListItem.dark
        let lightItem = LottieAnimations.SkeletonListItem.light

        return colorScheme == .dark ? darkItem : lightItem
    }
}
