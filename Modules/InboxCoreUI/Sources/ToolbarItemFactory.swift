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

import InboxDesignSystem
import SwiftUI

public enum ToolbarItemFactory {
    public static func back(action: @escaping () -> Void) -> some ToolbarContent {
        leading(Image(symbol: .chevronLeft), action: action)
    }

    public static func leading(_ image: Image, action: @escaping () -> Void) -> some ToolbarContent {
        button(.topBarLeading, image, DS.Color.Icon.weak, action: action)
    }

    public static func trailing(_ image: Image, action: @escaping () -> Void) -> some ToolbarContent {
        button(.topBarTrailing, image, DS.Color.Icon.accent, action: action)
    }

    public static func trailing(_ title: String, action: @escaping () -> Void) -> some ToolbarContent {
        button(.topBarTrailing, title, action: action)
    }

    // MARK: - Private

    private static func button(
        _ placement: ToolbarItemPlacement,
        _ title: String,
        action: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button(title, action: action)
                .buttonStyle(ToolbarButtonStyle())
        }
    }

    private static func button(
        _ placement: ToolbarItemPlacement,
        _ image: Image,
        _ iconColor: Color,
        action: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button(action: action) {
                image
                    .foregroundStyle(iconColor)
            }
        }
    }
}

private struct ToolbarButtonStyle: ButtonStyle {
    public init() {}

    // MARK: - ButtonStyle

    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(
                configuration.isPressed ? DS.Color.InteractionBrand.pressed : DS.Color.InteractionBrand.norm
            )
    }
}
