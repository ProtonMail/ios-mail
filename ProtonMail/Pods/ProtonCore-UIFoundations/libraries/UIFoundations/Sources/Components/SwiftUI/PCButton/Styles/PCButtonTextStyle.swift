//
//  PCButtonTextStyle.swift
//  ProtonCore-UIFoundations - Created on 27.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import SwiftUI

struct PCButtonTextStyle: ButtonStyle {
    let brand: Brand
    let isEnabled: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .font(.subheadline)
            .foregroundColor(titleColor(configuration: configuration))
    }

    private func titleColor(configuration: Self.Configuration) -> Color {
        guard isEnabled else {
            return ColorProvider.TextWeak.opacity(0.4)
        }
        var titleColorNormal: Color
        switch brand {
        case .proton, .vpn:
            titleColorNormal = ColorProvider.TextAccent
        case .pass:
            titleColorNormal = ColorProvider.InteractionNormMajor2PassTheme
        }
        return configuration.isPressed ?
        ColorProvider.InteractionNormPressed :
        titleColorNormal
    }
}

#endif
