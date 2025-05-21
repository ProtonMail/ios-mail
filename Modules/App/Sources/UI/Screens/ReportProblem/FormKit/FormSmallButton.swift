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

struct FormSmallButton: View {
    private let title: LocalizedStringResource
    private let rightSymbol: Symbol?
    private let action: () -> Void

    struct Symbol {
        let name: String
        let color: Color
    }

    init(
        title: LocalizedStringResource,
        rightSymbol: Symbol?,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.rightSymbol = rightSymbol
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            Button(action: { action() }) {
                HStack {
                    Text(title)
                        .foregroundStyle(DS.Color.Text.norm)
                    Spacer(minLength: DS.Spacing.medium)
                    if let rightSymbol {
                        Image(systemName: rightSymbol.name)
                            .foregroundStyle(rightSymbol.color)
                    }
                }
                .padding(.vertical, DS.Spacing.moderatelyLarge)
                .padding(.horizontal, DS.Spacing.large)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(SettingsButtonStyle())
        }
    }
}

extension FormSmallButton.Symbol {

    static var checkmark: Self {
        .init(name: DS.SFSymbols.checkmark, color: DS.Color.Icon.accent)
    }

    static var chevronRight: Self {
        .init(name: DS.SFSymbols.chevronRight, color: DS.Color.Text.hint)
    }

}
