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

import SwiftUI
import DesignSystem
import ProtonCoreUI

struct MailboxActionBarMoreSheetState: Identifiable {
    let selectedItemsIDs: Set<ID>
    let visibleActions: [BottomBarAction]
    let hiddenActions: [BottomBarAction]

    // MARK: - Identifiable

    var id: Set<ID> {
        selectedItemsIDs
    }
}

struct MailboxActionBarMoreSheet: View {
    let state: MailboxActionBarMoreSheetState
    let actionTapped: (BottomBarAction) -> Void

    init(state: MailboxActionBarMoreSheetState, actionTapped: @escaping (BottomBarAction) -> Void) {
        self.state = state
        self.actionTapped = actionTapped
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    section(content: state.hiddenActions)
                    section(content: state.visibleActions)
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle("\(state.selectedItemsIDs.count) Selected".notLocalized) // FIXME: - Add localization
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Private

    private func section(content: [BottomBarAction]) -> some View {
        ActionSheetSection {
            ForEachLast(collection: content) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.actionDisplayData,
                    displayBottomSeparator: !isLast,
                    action: { actionTapped(action) }
                )
            }
        }
    }
}

extension BottomBarAction {
    var actionDisplayData: ActionDisplayData {
        .init(title: displayModel.name.unsafelyUnwrapped, image: displayModel.icon)
    }
}

#Preview {
    MailboxActionBarMoreSheet(state: .init(
        selectedItemsIDs: [.init(value: 1), .init(value: 2), .init(value: 3)],
        visibleActions: [
            .markUnread,
            .moveToSystemFolder(.init(localId: .init(value: 4), systemLabel: .archive)),
            .moveToSystemFolder(.init(localId: .init(value: 5), systemLabel: .inbox)),
            .moveToSystemFolder(.init(localId: .init(value: 6), systemLabel: .trash)),
            .star
        ],
        hiddenActions: [
            .labelAs,
            .moveTo,
            .moveToSystemFolder(.init(localId: .init(value: 7), systemLabel: .spam))
        ]
    ), actionTapped: { _ in })
}
