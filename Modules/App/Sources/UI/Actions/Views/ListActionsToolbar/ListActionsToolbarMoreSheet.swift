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

import proton_app_uniffi
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct ListActionsToolbarMoreSheet: View {
    let state: ListActionsToolbarMoreSheetState
    let actionTapped: (ListActions) -> Void
    let editToolbarTapped: () -> Void

    init(
        state: ListActionsToolbarMoreSheetState,
        actionTapped: @escaping (ListActions) -> Void,
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

                    editToolbarSection()
                }
                .padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(L10n.Mailbox.selected(emailsCount: state.selectedItemsIDs.count).string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Private

    private func section(content: [ListActions]) -> some View {
        ActionSheetSection {
            ForEachLast(collection: content) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { actionTapped(action) }
                )
            }
        }
    }

    private func editToolbarSection() -> some View {
        EditToolbarSheetSection {
            editToolbarTapped()
        }
    }

}

#Preview {
    ListActionsToolbarMoreSheet(
        state: ListActionsToolbarMoreSheetPreviewProvider.state(),
        actionTapped: { _ in },
        editToolbarTapped: {}
    )
}
