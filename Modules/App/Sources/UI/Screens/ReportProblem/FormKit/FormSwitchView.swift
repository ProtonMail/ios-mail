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

import SwiftUI
import InboxDesignSystem

struct FormSwitchView: View {
    private let title: LocalizedStringResource
    @Binding private var isOn: Bool

    init(title: LocalizedStringResource, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            HStack {
                Text(title)
                Spacer(minLength: DS.Spacing.standard)
                Toggle(String.empty, isOn: $isOn)
                    .tint(DS.Color.Text.accent)
            }
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, DS.Spacing.mediumLight)
            .frame(maxWidth: .infinity)
            .background(DS.Color.BackgroundInverted.secondary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Spacing.mediumLight))
        }
    }
}
