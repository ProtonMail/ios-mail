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

struct CTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(ColorProvider.InteractionNorm)
            .cornerRadius(8)
            .font(Font(UIFont.adjustedFont(forTextStyle: .body)))
            .foregroundColor(Color.white)
    }
}

struct CrossButton: View {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            IconProvider.cross
                .foregroundColor(ColorProvider.SidebarIconNorm)
                .frame(width: 40, height: 40)
        })
    }
}

#Preview {
    VStack {
        Button("OK") {

        }
        .buttonStyle(CTAButtonStyle())

        CrossButton { }
    }
}
