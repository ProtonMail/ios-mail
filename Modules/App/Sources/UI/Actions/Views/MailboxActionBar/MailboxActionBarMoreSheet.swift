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

struct MailboxActionBarMoreSheet: View {
    let state: MailboxActionBarMoreSheetState
    let actionTapped: (BottomBarAction) -> Void
    let editToolbarTapped: () -> Void

    init(
        state: MailboxActionBarMoreSheetState,
        actionTapped: @escaping (BottomBarAction) -> Void,
        editToolbarTapped: @escaping () -> Void
    ) {
        self.state = state
        self.actionTapped = actionTapped
        self.editToolbarTapped = editToolbarTapped
    }
    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.large) {
                    section(content: state.moreSheetOnlyActions)
                    section(content: state.bottomBarActions)

                    if CustomizeToolbarsFlag.isVisible {
                        editToolbarSection()
                    }
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(L10n.Mailbox.selected(emailsCount: state.selectedItemsIDs.count).string)
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

    private func editToolbarSection() -> some View {
        ActionSheetSection {
            ActionSheetImageButton(
                displayData: .init(title: L10n.Action.editToolbar, image: DS.Icon.icMagicWand.image),
                displayBottomSeparator: false
            ) {
                editToolbarTapped()
            }
        }
    }

}

private extension BottomBarAction {
    var actionDisplayData: ActionDisplayData {
        .init(title: displayData.name.unsafelyUnwrapped, image: displayData.icon)
    }
}

#Preview {
    MailboxActionBarMoreSheet(
        state: MailboxActionBarMoreSheetPreviewProvider.state(),
        actionTapped: { _ in },
        editToolbarTapped: {}
    )
}
