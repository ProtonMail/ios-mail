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

public struct FormSmallButton: View {
    private let title: LocalizedStringResource
    private let rightSymbol: Symbol?
    private let action: () -> Void

    public struct Symbol {
        let name: DS.SFSymbol
        let color: Color
    }

    public init(
        title: LocalizedStringResource,
        rightSymbol: Symbol?,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.rightSymbol = rightSymbol
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            Button(action: { action() }) {
                HStack {
                    Text(title)
                        .foregroundStyle(DS.Color.Text.norm)
                    Spacer(minLength: DS.Spacing.medium)
                    if let rightSymbol {
                        Image(symbol: rightSymbol.name)
                            .foregroundStyle(rightSymbol.color)
                    }
                }
                .padding(.vertical, DS.Spacing.moderatelyLarge)
                .padding(.horizontal, DS.Spacing.large)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(DefaultPressedButtonStyle())
            .background(DS.Color.BackgroundInverted.secondary)
        }
    }
}

extension FormSmallButton.Symbol {

    public static var checkmark: Self {
        .init(name: .checkmark, color: DS.Color.Icon.accent)
    }

    public static var chevronRight: Self {
        .init(name: .chevronRight, color: DS.Color.Text.hint)
    }

}
