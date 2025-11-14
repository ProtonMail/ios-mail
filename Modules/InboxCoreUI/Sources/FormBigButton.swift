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
import ProtonUIFoundations
import SwiftUI

public struct FormBigButton: View {
    public enum AccessoryType {
        case symbol(SFSymbol)
        case upsell
    }

    private let title: LocalizedStringResource
    private let value: String
    private let accessoryType: AccessoryType
    private let action: () -> Void

    public init(
        title: LocalizedStringResource,
        accessoryType: AccessoryType,
        value: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.accessoryType = accessoryType
        self.value = value
        self.action = action
    }

    public init(
        title: LocalizedStringResource,
        symbol: SFSymbol,
        value: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.accessoryType = .symbol(symbol)
        self.value = value
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            FormBigButtonContent<EmptyView>(
                title: title,
                value: value,
                hasAccentTextColor: false,
                accessoryType: accessoryType,
                bottomContent: { nil }
            )
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
        .roundedRectangleStyle()
    }
}
