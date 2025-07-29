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

struct FormSecureTextInput: View {
    private let title: LocalizedStringResource
    @Binding private var text: String
    @State var secureEntry: Bool = true

    init(
        title: LocalizedStringResource,
        text: Binding<String>
    ) {
        self.title = title
        self._text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            HStack(spacing: DS.Spacing.mediumLight) {
                SecureInput(configuration: .pinSettingsInput, text: $text, isSecure: $secureEntry)
                    .frame(height: 22)
                Button(action: { secureEntry.toggle() }) {
                    Image(symbol: secureEntry ? .eye : .eyeSlash)
                        .foregroundStyle(DS.Color.Text.hint)
                }
            }
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .frame(maxWidth: .infinity)
    }
}
