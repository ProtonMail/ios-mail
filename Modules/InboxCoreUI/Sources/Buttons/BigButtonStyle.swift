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
    public enum Flavor {
        case regular
        case inverted(backgroundColorOverride: Color?)
        case weak

        var foregroundColor: Color {
            switch self {
            case .regular:
                DS.Color.Text.inverted
            case .inverted:
                DS.Color.Text.norm
            case .weak:
                DS.Color.Brand.plus30
            }
        }

        func backgroundColor(isPressed: Bool) -> Color {
            switch self {
            case .regular:
                isPressed ? DS.Color.InteractionBrand.pressed : DS.Color.InteractionBrand.norm
            case .inverted(let override):
                override ?? DS.Color.Background.norm
            case .weak:
                isPressed ? DS.Color.InteractionBrandWeak.pressed : DS.Color.InteractionBrandWeak.norm
            }
        }
    }

    private let flavor: Flavor

    public init(flavor: Flavor = .regular) {
        self.flavor = flavor
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(flavor.foregroundColor)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                flavor.backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: DS.Radius.massive)
            )
    }
}
