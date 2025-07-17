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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct StarImage: View {
    private let isStarred: Bool
    private let size: CGFloat

    init(isStarred: Bool, size: CGFloat) {
        self.isStarred = isStarred
        self.size = size
    }

    var body: some View {
        Image(isStarred ? DS.Icon.icStarFilledStrong : DS.Icon.icStarStrong)
            .resizable()
            .square(size: size)
            .foregroundColor(isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
    }
}
