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

struct ConversationTopTitle: Hashable {
    let title: String
    let subtitle: String?
}

struct ConversationToolbar<TrailingButton: View>: ViewModifier {
    let titleState: ConversationTopTitle?
    let trailingButton: () -> TrailingButton?

    var toolbarItemPlacement: ToolbarItemPlacement {
        if #available(iOS 26, *) {
            return .subtitle
        } else {
            return .title
        }
    }

    func body(content: Content) -> some View {
        content
            .toolbarRole(.browser)
            .toolbar {
                ToolbarItem(placement: toolbarItemPlacement) {
                    VStack(alignment: .leading) {
                        if let titleState {
                            Text(titleState.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let subtitle = titleState.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(DS.Color.Text.weak)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .modify { view in
                        // Without this the animation of header is broken on iOS 17,18
                        if #unavailable(iOS 26) {
                            view
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingButton()
                }
            }
    }
}

extension View {
    func conversationTopToolbar(
        titleState: ConversationTopTitle?,
        trailingButton: @escaping () -> some View
    ) -> some View {
        modifier(ConversationToolbar(titleState: titleState, trailingButton: trailingButton))
    }
}
