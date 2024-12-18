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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct BottomActionBarView: View {
    private let actions: [BottomBarAction]
    private let tapAction: (BottomBarAction) -> Void

    init(actions: [BottomBarAction], tapAction: @escaping (BottomBarAction) -> Void) {
        self.actions = actions
        self.tapAction = tapAction
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    ForEachEnumerated(actions, id: \.offset) { action, index in
                        Button(action: { tapAction(action) }) {
                            Image(action.displayData.icon)
                                .foregroundStyle(DS.Color.Icon.weak)
                        }
                        .accessibilityIdentifier(MailboxActionBarViewIdentifiers.button(index: index))
                        Spacer()
                    }
                }
                .frame(
                    width: min(geometry.size.width, geometry.size.height),
                    height: 45 + geometry.safeAreaInsets.bottom
                )
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .compositingGroup()
                .shadow(radius: 2)
                .tint(DS.Color.Text.norm)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.rootItem)
            }
        }
    }
}

#Preview {
    BottomActionBarView(
        actions: [.markRead, .labelAs, .moveTo, .notSpam(.init(localId: ID.random(), systemLabel: .inbox)), .more], 
        tapAction: { _ in }
    )
}

// MARK: Accessibility

private struct MailboxActionBarViewIdentifiers {
    static let rootItem = "mailbox.actionBar.rootItem"

    static func button(index: Int) -> String {
        let number = index + 1
        return "mailbox.actionBar.button\(number)"
    }
}
