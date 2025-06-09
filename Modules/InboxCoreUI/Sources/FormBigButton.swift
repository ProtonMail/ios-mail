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

public struct FormBigButton: View {
    private let title: LocalizedStringResource
    private let value: String
    private let symbol: DS.SFSymbol?
    private let action: () -> Void

    public init(
        title: LocalizedStringResource,
        symbol: DS.SFSymbol?,
        value: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.value = value
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            FormBigButtonContent(
                title: title,
                value: value,
                hasAccentTextColor: false,
                symbol: symbol
            )
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .buttonStyle(DefaultPressedButtonStyle())
    }
}
