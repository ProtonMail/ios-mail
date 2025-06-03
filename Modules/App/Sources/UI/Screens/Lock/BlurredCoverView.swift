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

import SwiftUI
import InboxDesignSystem

struct BlurredCoverView: View {
    private let showLogo: Bool

    init(showLogo: Bool) {
        self.showLogo = showLogo
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                TransparentBlur()

                if showLogo {
                    Image
                        .protonLogo(size: 120)
                        .padding(.top, geometry.size.height * 0.37)
                }
            }
        }.ignoresSafeArea()
    }
}
