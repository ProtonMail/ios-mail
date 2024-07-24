//
//  PCButton.swift
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

public struct PCButton: View {
    @Binding public var style: PCButtonStyle
    @Binding public var content: PCButtonContent

    public init(style: Binding<PCButtonStyle>, content: Binding<PCButtonContent>) {
        self._style = style
        self._content = content
    }

    public var body: some View {
        Button(action: content.action) {
            ZStack(alignment: .trailing) {
                Text(content.title)
                    .frame(maxWidth: .infinity)

                if content.isAnimating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                }
            }
        }
        .buttonStyle(PCButtonModeStyle(brand: style.brand, mode: style.mode))
        .disabled(!content.isEnabled || content.isAnimating)
    }
}

#endif
