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

public struct FormSection<Content: View>: View {

    private let header: LocalizedStringResource?
    private let footer: LocalizedStringResource?
    private let content: () -> Content

    public init(
        header: LocalizedStringResource? = nil,
        footer: LocalizedStringResource? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.compact) {
            if let header {
                Text(header)
                    .font(.callout)
                    .foregroundStyle(DS.Color.Text.norm)
                    .fontWeight(.semibold)
                    .padding(.leading, DS.Spacing.large)
                    .padding(.bottom, DS.Spacing.small)
            }

            content()

            if let footer {
                FormFootnoteText(footer)
                    .padding(.horizontal, DS.Spacing.large)
            }
        }
        .padding(.top, DS.Spacing.large)
    }

}
