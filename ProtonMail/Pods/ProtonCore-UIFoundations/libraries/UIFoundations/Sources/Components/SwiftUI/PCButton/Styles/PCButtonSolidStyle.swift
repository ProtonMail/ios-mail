//
//  PCButtonButtonStyle.swift
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

struct PCButtonSolidStyle: ButtonStyle {
    let brand: Brand
    let isEnabled: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .font(.body)
            .foregroundColor(titleColor(configuration: configuration))
            .background(backgroundColor(configuration: configuration))
            .cornerRadius(cornerRadius())
    }

    private func titleColor(configuration: Self.Configuration) -> Color {
        guard isEnabled else {
            return ColorProvider.White.opacity(0.4)
        }
        return ColorProvider.White
    }

    private func backgroundColor(configuration: Self.Configuration) -> Color {
        guard isEnabled else {
            return ColorProvider.InteractionNormDisabled
        }
        var backgroundNormal: Color
        switch brand {
        case .proton, .vpn:
            backgroundNormal = ColorProvider.InteractionNorm
        case .pass:
            backgroundNormal = ColorProvider.InteractionNormMajor1PassTheme
        }
        return configuration.isPressed ?
        ColorProvider.InteractionNormPressed :
        backgroundNormal
    }

    private func cornerRadius() -> CGFloat {
        switch brand {
        case .proton, .vpn:
            return 8.0
        case .pass:
            return 24.0
        }
    }
}
#endif
