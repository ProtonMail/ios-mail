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
import Lottie
import SwiftUI

struct MailboxSkeletonView: View {
    @Environment(\.colorScheme) var colorScheme

    // MARK: - View

    var body: some View {
        List(0..<25) { _ in
            rowView()
        }
        .scrollDisabled(true)
        .listStyle(.plain)
        .listRowSpacing(DS.Spacing.huge)
        .padding(.top, DS.Spacing.huge)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Private

    private func rowView() -> some View {
        LottieView(animation: animation(for: colorScheme))
            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.trailing, 60)
            .listRowBackground(Color.clear)
            .listRowInsets(.init(vertical: .zero, horizontal: DS.Spacing.large))
            .listRowSeparator(.hidden)
    }

    private func animation(for colorScheme: ColorScheme) -> LottieAnimation {
        let darkItem = LottieAnimations.skeletonListItemDark
        let lightItem = LottieAnimations.skeletonListItemLight

        return colorScheme == .dark ? darkItem : lightItem
    }
}

private enum LottieAnimations {
    static let skeletonListItemLight: LottieAnimation = .named("skeleton_list_item_light").unsafelyUnwrapped
    static let skeletonListItemDark: LottieAnimation = .named("skeleton_list_item_dark").unsafelyUnwrapped
}

#Preview {
    MailboxSkeletonView()
}
