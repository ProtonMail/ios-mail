// Copyright (c) 2026 Proton Technologies AG
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

struct LiquidComposeButton: ToolbarContent {
    @Environment(\.mainBundle) private var mainBundle

    let isExpanded: Bool
    let action: () -> Void
    @Namespace private var buttonTransition
    private let buttonTransitionIdentifier = "buttonTransition"

    var body: some ToolbarContent {
        if isExpanded {
            ToolbarItem(placement: .bottomBar) {
                Button(
                    action: action,
                    label: {
                        HStack(spacing: DS.Spacing.standard) {
                            Image(DS.Icon.icPenSquare)
                                .foregroundStyle(DS.Color.Icon.norm)
                            Text(L10n.Mailbox.compose)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(DS.Color.Icon.norm)
                        }
                        .padding(.horizontal, DS.Spacing.compact)
                    }
                )
                .modify { view in
                    if #available(iOS 26, *), mainBundle.isLiquidGlassEnabled {
                        view
                            .matchedTransitionSource(id: buttonTransitionIdentifier, in: buttonTransition)
                    }
                }
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                Button(L10n.Mailbox.compose, image: DS.Icon.icPenSquare, action: action)
                    .modify { view in
                        if #available(iOS 26, *), mainBundle.isLiquidGlassEnabled {
                            view
                                .matchedTransitionSource(id: buttonTransitionIdentifier, in: buttonTransition)
                        }
                    }
            }
        }
    }
}
