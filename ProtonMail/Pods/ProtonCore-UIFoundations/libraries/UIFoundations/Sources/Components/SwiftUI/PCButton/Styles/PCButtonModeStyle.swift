//
//  PCButtonModeStyle.swift
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

struct PCButtonModeStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    let brand: Brand
    let mode: PCButtonStyle.ButtonMode

    func makeBody(configuration: Configuration) -> some View {
        switch mode {
        case .solid:
            PCButtonSolidStyle(brand: brand, isEnabled: isEnabled)
                .makeBody(configuration: configuration)
        case .text:
            PCButtonTextStyle(brand: brand, isEnabled: isEnabled)
                .makeBody(configuration: configuration)
        }
    }
}

#endif
