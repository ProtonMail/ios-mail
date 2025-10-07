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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ConversationsPageViewController: View {
    @Environment(\.presentationMode) var presentationMode

    let startingItem: MailboxItemCellUIModel
    let mailboxCursor: MailboxCursor

    let draftPresenter: DraftPresenter
    var navigationPath: Binding<NavigationPath>
    var selectedMailbox: SelectedMailbox
    let userSession: MailUserSession

    @State var activeModel: ConversationDetailModel?

    var body: some View {
        PageViewController(
            startingItem: startingItem,
            cursor: mailboxCursor,
            pageFactory: pageFactory
        )
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        Image(symbol: .chevronLeft)
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                )
                .square(size: 40)
            }
        }
        .background {
            if let activeModel {
                ConversationDetailToolbars(model: activeModel, navigationPath: navigationPath)
            }
        }
    }

    private func pageFactory(item: MailboxItemCellUIModel) -> ConversationDetailScreen {
        .init(
            seed: .mailboxItem(item: item, selectedMailbox: selectedMailbox),
            draftPresenter: draftPresenter,
            navigationPath: navigationPath,
            mailUserSession: userSession,
            onLoad: { if activeModel == nil { activeModel = $0 } },
            onDidAppear: { activeModel = $0 }
        )
    }
}
