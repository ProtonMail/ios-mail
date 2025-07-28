//
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

import InboxDesignSystem
import SwiftUI

public struct BigButtonStyle: ButtonStyle {
    private let invertColorScheme: Bool

    private var foregroundColor: Color {
        invertColorScheme ? DS.Color.Text.norm : DS.Color.Text.inverted
    }

    public init(invertColorScheme: Bool = false) {
        self.invertColorScheme = invertColorScheme
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: DS.Radius.massive)
            )
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if invertColorScheme {
            DS.Color.Background.norm
        } else {
            isPressed ? DS.Color.InteractionBrand.pressed : DS.Color.InteractionBrand.norm
        }
    }
}
